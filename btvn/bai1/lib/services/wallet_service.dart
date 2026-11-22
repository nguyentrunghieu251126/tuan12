import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

import '../models/app_user.dart';
import '../models/wallet_transaction.dart';
import 'firebase_db.dart';

class WalletService {
  final Logger _logger = Logger();

  CollectionReference<Map<String, dynamic>> get _users =>
      appDb.collection('users');
  CollectionReference<Map<String, dynamic>> get _txs =>
      appDb.collection('transactions');

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // Tạo hồ sơ users/{uid} khi đăng ký
  Future<void> createUserProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) {
    return _users.doc(uid).set({
      'fullName': fullName,
      'email': email.trim().toLowerCase(),
      'phone': phone,
      'avatarUrl': '',
      'balance': 0,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Theo dõi hồ sơ, nếu chưa có thì tự tạo từ thông tin đăng nhập
  Stream<AppUser?> watchCurrentUser() {
    final user = FirebaseAuth.instance.currentUser!;
    return _users.doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) {
        createUserProfile(
          uid: user.uid,
          fullName: user.displayName ?? '',
          email: user.email ?? '',
          phone: '',
        );
        return null;
      }
      return AppUser.fromDoc(doc);
    });
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    await _users.doc(_uid).set(
      {'fullName': fullName, 'phone': phone},
      SetOptions(merge: true),
    );
    await FirebaseAuth.instance.currentUser!.updateDisplayName(fullName);
  }

  // Upload ảnh đại diện lên Storage rồi lưu link vào Firestore
  Future<void> uploadAvatar(File file) async {
    String ext = path.extension(file.path);
    final storageRef =
        FirebaseStorage.instance.ref('avatars').child('$_uid$ext');
    await storageRef.putFile(file);
    final downloadURL = await storageRef.getDownloadURL();
    await _users.doc(_uid).set(
      {'avatarUrl': downloadURL},
      SetOptions(merge: true),
    );
    await FirebaseAuth.instance.currentUser!.updatePhotoURL(downloadURL);
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final query = await _users
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return AppUser.fromDoc(query.docs.first);
  }

  // Giao dịch của user hiện tại, sắp xếp trong app nên không cần tạo index
  Stream<List<WalletTransaction>> watchTransactions() {
    return _txs.where('uid', isEqualTo: _uid).snapshots().map((query) {
      final list =
          query.docs.map((doc) => WalletTransaction.fromDoc(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Map<String, dynamic> _txData({
    required String uid,
    required TxType type,
    required double amount,
    required String note,
    required double balanceAfter,
    String counterpartName = '',
    String counterpartEmail = '',
  }) {
    return {
      'uid': uid,
      'type': WalletTransaction.typeToString[type],
      'amount': amount,
      'note': note,
      'counterpartName': counterpartName,
      'counterpartEmail': counterpartEmail,
      'balanceAfter': balanceAfter,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Future<double> _getBalance(String uid) async {
    final snap = await _users.doc(uid).get();
    return (snap.data()?['balance'] as num?)?.toDouble() ?? 0;
  }

  // Nạp tiền: cộng số dư + ghi giao dịch trong cùng 1 batch
  Future<void> deposit(double amount, String note) async {
    final balance = await _getBalance(_uid);
    final batch = appDb.batch();
    batch.set(
      _users.doc(_uid),
      {'balance': FieldValue.increment(amount)},
      SetOptions(merge: true),
    );
    batch.set(
      _txs.doc(),
      _txData(
        uid: _uid,
        type: TxType.deposit,
        amount: amount,
        note: note,
        balanceAfter: balance + amount,
      ),
    );
    await batch.commit();
    _logger.i('Deposit $amount done');
  }

  // Rút tiền
  Future<void> withdraw(double amount, String note) async {
    final balance = await _getBalance(_uid);
    if (balance < amount) throw Exception('Số dư không đủ');
    final batch = appDb.batch();
    batch.set(
      _users.doc(_uid),
      {'balance': FieldValue.increment(-amount)},
      SetOptions(merge: true),
    );
    batch.set(
      _txs.doc(),
      _txData(
        uid: _uid,
        type: TxType.withdraw,
        amount: amount,
        note: note,
        balanceAfter: balance - amount,
      ),
    );
    await batch.commit();
    _logger.i('Withdraw $amount done');
  }

  // Chuyển khoản theo email người nhận
  Future<void> transfer(
      String receiverEmail, double amount, String note) async {
    final receiver = await findUserByEmail(receiverEmail);
    if (receiver == null) throw Exception('Không tìm thấy người nhận');
    if (receiver.uid == _uid)
      throw Exception('Không thể chuyển cho chính mình');

    final senderSnap = await _users.doc(_uid).get();
    final sender = AppUser.fromDoc(senderSnap);
    if (sender.balance < amount) throw Exception('Số dư không đủ');

    // Trừ người gửi, cộng người nhận, ghi 2 giao dịch
    final batch = appDb.batch();
    batch.set(
      _users.doc(_uid),
      {'balance': FieldValue.increment(-amount)},
      SetOptions(merge: true),
    );
    batch.set(
      _users.doc(receiver.uid),
      {'balance': FieldValue.increment(amount)},
      SetOptions(merge: true),
    );
    batch.set(
      _txs.doc(),
      _txData(
        uid: _uid,
        type: TxType.transferOut,
        amount: amount,
        note: note,
        balanceAfter: sender.balance - amount,
        counterpartName: receiver.fullName,
        counterpartEmail: receiver.email,
      ),
    );
    batch.set(
      _txs.doc(),
      _txData(
        uid: receiver.uid,
        type: TxType.transferIn,
        amount: amount,
        note: note,
        balanceAfter: receiver.balance + amount,
        counterpartName: sender.fullName,
        counterpartEmail: sender.email,
      ),
    );
    await batch.commit();
    _logger.i('Transfer $amount to ${receiver.email} done');
  }
}
