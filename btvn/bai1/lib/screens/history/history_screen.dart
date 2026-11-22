import 'package:flutter/material.dart';

import '../../models/wallet_transaction.dart';
import '../../services/wallet_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/transaction_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Stream<List<WalletTransaction>> _txStream =
      WalletService().watchTransactions();
  TxType? _filter;

  static const Map<TxType?, String> _labels = {
    null: 'Tất cả',
    TxType.deposit: 'Nạp tiền',
    TxType.withdraw: 'Rút tiền',
    TxType.transferOut: 'Chuyển đi',
    TxType.transferIn: 'Nhận tiền',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Lịch sử giao dịch',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _labels.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _filter == e.key,
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          onSelected: (_) => setState(() => _filter = e.key),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WalletTransaction>>(
              stream: _txStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Lỗi: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!
                    .where((t) => _filter == null || t.type == _filter)
                    .toList();
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Không có giao dịch',
                        style: TextStyle(color: AppColors.textGrey)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => TransactionTile(tx: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
