import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/wallet_transaction.dart';
import '../../services/wallet_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/transaction_tile.dart';

enum StatPeriod { month, quarter, year, custom }

class _Bucket {
  final String label;
  final DateTime start;
  final DateTime end;
  double income = 0;
  double expense = 0;
  _Bucket(this.label, this.start, this.end);
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final Stream<List<WalletTransaction>> _txStream =
      WalletService().watchTransactions();

  StatPeriod _period = StatPeriod.month;
  DateTime _anchor = DateTime.now();
  DateTimeRange? _customRange;

  // Khoảng thời gian [start, end) theo kỳ đang chọn
  (DateTime, DateTime) get _range {
    final a = _anchor;
    switch (_period) {
      case StatPeriod.month:
        return (DateTime(a.year, a.month, 1), DateTime(a.year, a.month + 1, 1));
      case StatPeriod.quarter:
        final firstMonth = ((a.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime(a.year, firstMonth, 1),
          DateTime(a.year, firstMonth + 3, 1)
        );
      case StatPeriod.year:
        return (DateTime(a.year, 1, 1), DateTime(a.year + 1, 1, 1));
      case StatPeriod.custom:
        final now = DateTime.now();
        final r = _customRange ??
            DateTimeRange(
                start: now.subtract(const Duration(days: 29)), end: now);
        return (
          DateTime(r.start.year, r.start.month, r.start.day),
          DateTime(r.end.year, r.end.month, r.end.day + 1)
        );
    }
  }

  String get _rangeLabel {
    final (start, end) = _range;
    switch (_period) {
      case StatPeriod.month:
        return 'Tháng ${start.month}/${start.year}';
      case StatPeriod.quarter:
        return 'Quý ${(start.month - 1) ~/ 3 + 1}/${start.year}';
      case StatPeriod.year:
        return 'Năm ${start.year}';
      case StatPeriod.custom:
        return '${formatDate(start)} - ${formatDate(end.subtract(const Duration(days: 1)))}';
    }
  }

  void _shift(int dir) {
    setState(() {
      switch (_period) {
        case StatPeriod.month:
          _anchor = DateTime(_anchor.year, _anchor.month + dir, 1);
          break;
        case StatPeriod.quarter:
          _anchor = DateTime(_anchor.year, _anchor.month + 3 * dir, 1);
          break;
        case StatPeriod.year:
          _anchor = DateTime(_anchor.year + dir, 1, 1);
          break;
        case StatPeriod.custom:
          break;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _customRange,
      helpText: 'Chọn khoảng thời gian',
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = StatPeriod.custom;
      });
    }
  }

  // Chia khoảng thời gian thành các cột biểu đồ (theo tuần hoặc theo tháng)
  List<_Bucket> _buildBuckets(DateTime start, DateTime end) {
    final buckets = <_Bucket>[];
    final days = end.difference(start).inDays;
    final byWeek = _period == StatPeriod.month ||
        (_period == StatPeriod.custom && days <= 62);

    if (byWeek) {
      DateTime cursor = start;
      int i = 1;
      while (cursor.isBefore(end)) {
        DateTime next = cursor.add(const Duration(days: 7));
        if (next.isAfter(end)) next = end;
        final label =
            _period == StatPeriod.month ? 'Tuần $i' : formatShortDate(cursor);
        buckets.add(_Bucket(label, cursor, next));
        cursor = next;
        i++;
      }
    } else {
      DateTime cursor = DateTime(start.year, start.month, 1);
      while (cursor.isBefore(end)) {
        final next = DateTime(cursor.year, cursor.month + 1, 1);
        final bStart = cursor.isBefore(start) ? start : cursor;
        final bEnd = next.isAfter(end) ? end : next;
        buckets.add(_Bucket('Th${cursor.month}', bStart, bEnd));
        cursor = next;
      }
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<WalletTransaction>>(
        stream: _txStream,
        builder: (context, snap) {
          final (start, end) = _range;
          final all = snap.data ?? [];
          final txs = all
              .where((t) => !t.createdAt.isBefore(start) && t.createdAt.isBefore(end))
              .toList();

          final buckets = _buildBuckets(start, end);
          // Tính tổng thu, tổng chi và số liệu từng cột
          double income = 0, expense = 0;
          final Map<TxType, double> sumByType = {for (final t in TxType.values) t: 0};
          final Map<TxType, int> countByType = {for (final t in TxType.values) t: 0};

          for (final t in txs) {
            if (t.isIncome) {
              income += t.amount;
            } else {
              expense += t.amount;
            }
            sumByType[t.type] = sumByType[t.type]! + t.amount;
            countByType[t.type] = countByType[t.type]! + 1;
            for (final b in buckets) {
              if (!t.createdAt.isBefore(b.start) && t.createdAt.isBefore(b.end)) {
                if (t.isIncome) {
                  b.income += t.amount;
                } else {
                  b.expense += t.amount;
                }
                break;
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              const Text('Thống kê dòng tiền',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _periodSelector(),
              const SizedBox(height: 8),
              _rangeNavigator(),
              const SizedBox(height: 12),
              if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                        child: _summaryCard('Tổng thu', income, AppColors.income,
                            Icons.arrow_downward)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _summaryCard('Tổng chi', expense,
                            AppColors.expense, Icons.arrow_upward)),
                  ],
                ),
                const SizedBox(height: 12),
                _netCard(income - expense, txs.length),
                const SizedBox(height: 16),
                _chart(buckets),
                const SizedBox(height: 16),
                _breakdown(sumByType, countByType),
                const SizedBox(height: 16),
                Text('Giao dịch trong kỳ (${txs.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (txs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Không có giao dịch trong khoảng này',
                          style: TextStyle(color: AppColors.textGrey)),
                    ),
                  )
                else
                  ...txs.map((t) => TransactionTile(tx: t)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _periodSelector() {
    return SegmentedButton<StatPeriod>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: StatPeriod.month, label: Text('1 tháng')),
        ButtonSegment(value: StatPeriod.quarter, label: Text('1 quý')),
        ButtonSegment(value: StatPeriod.year, label: Text('1 năm')),
        ButtonSegment(value: StatPeriod.custom, label: Text('Tùy chọn')),
      ],
      selected: {_period},
      onSelectionChanged: (s) {
        final p = s.first;
        if (p == StatPeriod.custom) {
          _pickCustomRange();
        } else {
          setState(() {
            _period = p;
            _anchor = DateTime.now();
          });
        }
      },
    );
  }

  Widget _rangeNavigator() {
    if (_period == StatPeriod.custom) {
      return Row(
        children: [
          const Icon(Icons.date_range, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(_rangeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          TextButton(onPressed: _pickCustomRange, child: const Text('Đổi')),
        ],
      );
    }
    return Row(
      children: [
        IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => _shift(-1)),
        Expanded(
          child: Text(_rangeLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        IconButton(
            icon: const Icon(Icons.chevron_right), onPressed: () => _shift(1)),
      ],
    );
  }

  Widget _summaryCard(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatMoney(value),
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _netCard(double net, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark]),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dòng tiền ròng (thu - chi)',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('${net >= 0 ? '+' : ''}${formatMoney(net)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              Text('$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const Text('giao dịch', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chart(List<_Bucket> buckets) {
    final double maxVal = buckets.fold<double>(
        0, (m, b) => max(m, max(b.income, b.expense)));
    const double chartHeight = 140;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Biểu đồ thu chi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              _legend(AppColors.income, 'Thu'),
              const SizedBox(width: 12),
              _legend(AppColors.expense, 'Chi'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: chartHeight + 24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.map((b) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _bar(b.income, maxVal, chartHeight, AppColors.income),
                          const SizedBox(width: 2),
                          _bar(b.expense, maxVal, chartHeight, AppColors.expense),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 14,
                        child: FittedBox(
                          child: Text(b.label,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textGrey)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double value, double maxVal, double chartHeight, Color color) {
    final h = maxVal == 0 ? 2.0 : max(2.0, chartHeight * value / maxVal);
    return Tooltip(
      message: formatMoney(value),
      child: Container(
        width: 8,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _legend(Color color, String text) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      );

  Widget _breakdown(Map<TxType, double> sums, Map<TxType, int> counts) {
    const labels = {
      TxType.deposit: ('Nạp tiền', Icons.add_card, AppColors.income),
      TxType.transferIn: ('Nhận chuyển khoản', Icons.south_west, AppColors.income),
      TxType.withdraw: ('Rút tiền', Icons.account_balance, AppColors.expense),
      TxType.transferOut: ('Chuyển khoản đi', Icons.north_east, AppColors.expense),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: labels.entries.map((e) {
          final (name, icon, color) = e.value;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: color),
            title: Text(name),
            subtitle: Text('${counts[e.key]} giao dịch'),
            trailing: Text(formatMoney(sums[e.key]!),
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
  }
}
