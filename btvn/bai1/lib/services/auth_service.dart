import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

import 'wallet_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Đăng ký: tạo tài khoản rồi tạo hồ sơ ví với số dư 0
  Future<String?> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user!;
      await user.updateDisplayName(fullName);
      await WalletService().createUserProfile(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
      );
      _logger.i("User registered: ${user.email}");
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e("Error: ${e.message}");
      return _message(e);
    } catch (e) {
      _logger.e("Error: $e");
      return 'Đăng ký thất bại: $e';
    }
  }

  // Đăng nhập
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      _logger.i("User logged in: ${userCredential.user!.email}");
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e("Error: ${e.message}");
      return _message(e);
    }
  }

  // Quên mật khẩu: gửi email đặt lại
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e("Error: ${e.message}");
      return _message(e);
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 6 ký tự';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, vui lòng thử lại sau';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      default:
        return e.message ?? 'Đã có lỗi xảy ra';
    }
  }
}
