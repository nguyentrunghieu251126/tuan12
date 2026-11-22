import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/wallet_transaction.dart';
import '../../services/wallet_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/transaction_tile.dart';
import '../transaction/amount_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex) onOpenTab;
  const HomeScreen({super.key, required this.onOpenTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WalletService _walletService = WalletService();
  late final Stream<AppUser?> _userStream = _walletService.watchCurrentUser();
  late final Stream<List<WalletTransaction>> _txStream =
      _walletService.watchTransactions();

  void _open(AmountType type, {String? email}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AmountScreen(type: type, initialEmail: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<AppUser?>(
        stream: _userStream,
        builder: (context, userSnap) {
          final user = userSnap.data;
          return StreamBuilder<List<WalletTransaction>>(
            stream: _txStream,
            builder: (context, txSnap) {
              final txs = txSnap.data ?? [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  _header(user),
                  const SizedBox(height: 16),
                  _balanceCard(user),
                  if (user != null &&
                      (user.phone.isEmpty || user.avatarUrl.isEmpty)) ...[
                    const SizedBox(height: 16),
                    _upgradeCard(),
                  ],
                  const SizedBox(height: 24),
                  _transferAgain(txs),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('Giao dịch gần đây',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => widget.onOpenTab(2),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  if (txSnap.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (txs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Chưa có giao dịch nào',
                            style: TextStyle(color: AppColors.textGrey)),
                      ),
                    )
                  else
                    ...txs.take(5).map((t) => TransactionTile(tx: t)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _header(AppUser? user) {
    return Row(
      children: [
        const Text('zhippay',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(user == null ? 'Xin chào' : 'Chào, ${user.fullName.split(' ').last}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _balanceCard(AppUser? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng số dư',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        user == null ? '...' : formatMoney(user.balance),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Ví chính',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _action(Icons.add_card, 'Nạp tiền', () => _open(AmountType.deposit)),
              _action(Icons.send, 'Chuyển', () => _open(AmountType.transfer)),
              _action(Icons.account_balance, 'Rút tiền',
                  () => _open(AmountType.withdraw)),
              _action(Icons.bar_chart, 'Thống kê', () => widget.onOpenTab(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _upgradeCard() {
    return InkWell(
      onTap: () => widget.onOpenTab(3),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFEDEBFF),
              child: Icon(Icons.verified_user_outlined, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hoàn thiện hồ sơ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Cập nhật ảnh đại diện và số điện thoại',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _transferAgain(List<WalletTransaction> txs) {
    final Map<String, String> recent = {};
    for (final t in txs) {
      if (t.type == TxType.transferOut && !recent.containsKey(t.counterpartEmail)) {
        recent[t.counterpartEmail] = t.counterpartName;
      }
      if (recent.length >= 6) break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chuyển lại',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _person(
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.add, color: AppColors.primary),
                ),
                'Thêm mới',
                () => _open(AmountType.transfer),
              ),
              ...recent.entries.map(
                (e) => _person(
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      e.value.isEmpty ? '?' : e.value[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                  e.value.split(' ').last,
                  () => _open(AmountType.transfer, email: e.key),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _person(Widget avatar, String name, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            avatar,
            const SizedBox(height: 6),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
