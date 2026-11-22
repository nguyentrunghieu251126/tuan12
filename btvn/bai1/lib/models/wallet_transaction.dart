import 'package:cloud_firestore/cloud_firestore.dart';

enum TxType { deposit, withdraw, transferOut, transferIn }

class WalletTransaction {
  final String id;
  final String uid;
  final TxType type;
  final double amount;
  final String note;
  final String counterpartName;
  final String counterpartEmail;
  final double balanceAfter;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.note,
    required this.counterpartName,
    required this.counterpartEmail,
    required this.balanceAfter,
    required this.createdAt,
  });

  static const Map<TxType, String> typeToString = {
    TxType.deposit: 'deposit',
    TxType.withdraw: 'withdraw',
    TxType.transferOut: 'transfer_out',
    TxType.transferIn: 'transfer_in',
  };

  static TxType parseType(String? s) {
    return typeToString.entries
        .firstWhere((e) => e.value == s,
            orElse: () => const MapEntry(TxType.deposit, 'deposit'))
        .key;
  }

  factory WalletTransaction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    return WalletTransaction(
      id: doc.id,
      uid: data['uid'] ?? '',
      type: parseType(data['type']),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      note: data['note'] ?? '',
      counterpartName: data['counterpartName'] ?? '',
      counterpartEmail: data['counterpartEmail'] ?? '',
      balanceAfter: (data['balanceAfter'] as num?)?.toDouble() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  bool get isIncome => type == TxType.deposit || type == TxType.transferIn;

  String get title {
    switch (type) {
      case TxType.deposit:
        return 'Nạp tiền';
      case TxType.withdraw:
        return 'Rút tiền';
      case TxType.transferOut:
        return 'Chuyển đến $counterpartName';
      case TxType.transferIn:
        return 'Nhận từ $counterpartName';
    }
  }
}
