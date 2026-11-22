import 'package:flutter/material.dart';

import '../models/wallet_transaction.dart';
import '../utils/app_colors.dart';
import '../utils/format.dart';

class TransactionTile extends StatelessWidget {
  final WalletTransaction tx;
  const TransactionTile({super.key, required this.tx});

  IconData get _icon {
    switch (tx.type) {
      case TxType.deposit:
        return Icons.add_card;
      case TxType.withdraw:
        return Icons.account_balance;
      case TxType.transferOut:
        return Icons.north_east;
      case TxType.transferIn:
        return Icons.south_west;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncome ? AppColors.income : AppColors.expense;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_icon, color: AppColors.primary),
      ),
      title: Text(tx.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        tx.note.isNotEmpty ? tx.note : formatDateTime(tx.createdAt),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${tx.isIncome ? '+' : '-'}${formatMoney(tx.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          Text(formatDate(tx.createdAt),
              style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
        ],
      ),
    );
  }
}
