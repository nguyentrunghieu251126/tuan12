import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/wallet_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/format.dart';

enum AmountType { deposit, withdraw, transfer }

class AmountScreen extends StatefulWidget {
  final AmountType type;
  final String? initialEmail;
  const AmountScreen({super.key, required this.type, this.initialEmail});

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final WalletService _walletService = WalletService();
  StreamSubscription<AppUser?>? _userSub;
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail ?? '');
  final TextEditingController _noteController = TextEditingController();

  String _digits = '';
  AppUser? _receiver;
  bool _checkingReceiver = false;
  bool _submitting = false;
  double _balance = 0;

  int get _amount => int.tryParse(_digits) ?? 0;

  String get _title {
    switch (widget.type) {
      case AmountType.deposit:
        return 'Nạp tiền';
      case AmountType.withdraw:
        return 'Rút tiền';
      case AmountType.transfer:
        return 'Chuyển tiền';
    }
  }

  @override
  void initState() {
    super.initState();
    _userSub = _walletService.watchCurrentUser().listen((user) {
      if (mounted) setState(() => _balance = user?.balance ?? 0);
    });
    if (widget.initialEmail != null) _checkReceiver();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _press(String key) {
    setState(() {
      if (key == '<') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
      } else {
        final next = _digits + key;
        if (next.length <= 12) _digits = next.replaceFirst(RegExp(r'^0+'), '');
      }
    });
  }

  void _setQuick(int value) => setState(() => _digits = value.toString());

  Future<void> _checkReceiver() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _checkingReceiver = true);
    final user = await _walletService.findUserByEmail(email);
    if (!mounted) return;
    setState(() {
      _checkingReceiver = false;
      _receiver = user;
    });
    if (user == null) _showMessage('Không tìm thấy tài khoản với email này');
  }

  // Kiểm tra dữ liệu rồi gọi nạp / rút / chuyển
  Future<void> _submit() async {
    if (_amount <= 0) {
      _showMessage('Vui lòng nhập số tiền');
      return;
    }
    if (widget.type != AmountType.deposit && _amount > _balance) {
      _showMessage('Số dư không đủ');
      return;
    }
    if (widget.type == AmountType.transfer) {
      final email = _emailController.text.trim().toLowerCase();
      if (email.isEmpty) {
        _showMessage('Nhập email người nhận');
        return;
      }
      if (email == FirebaseAuth.instance.currentUser?.email?.toLowerCase()) {
        _showMessage('Không thể chuyển cho chính mình');
        return;
      }
    }

    setState(() => _submitting = true);
    final note = _noteController.text.trim();
    try {
      switch (widget.type) {
        case AmountType.deposit:
          await _walletService.deposit(_amount.toDouble(), note);
          break;
        case AmountType.withdraw:
          await _walletService.withdraw(_amount.toDouble(), note);
          break;
        case AmountType.transfer:
          await _walletService.transfer(
              _emailController.text.trim(), _amount.toDouble(), note);
          break;
      }
      if (!mounted) return;
      await _showSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showSuccess() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.income, size: 56),
        title: Text('$_title thành công'),
        content: Text(
          widget.type == AmountType.transfer
              ? 'Đã chuyển ${formatMoney(_amount)} đến ${_receiver?.fullName ?? _emailController.text.trim()}'
              : '$_title ${formatMoney(_amount)}',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _walletCard(),
            if (widget.type == AmountType.transfer) ...[
              const SizedBox(height: 12),
              _receiverField(),
            ],
            const SizedBox(height: 20),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatMoney(_amount),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                widget.type == AmountType.deposit
                    ? 'Tiền sẽ được cộng ngay vào ví'
                    : 'Số dư khả dụng: ${formatMoney(_balance)}',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [50000, 100000, 200000, 500000]
                  .map((v) => ActionChip(
                        label: Text(formatMoney(v)),
                        onPressed: () => _setQuick(v),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Ghi chú (không bắt buộc)',
                prefixIcon: Icon(Icons.edit_note),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            _keypad(),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Xác nhận ${_title.toLowerCase()}',
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _walletCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet,
                color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Số dư ví',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(formatMoney(_balance),
                    style: const TextStyle(color: AppColors.textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiverField() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_receiver != null) setState(() => _receiver = null);
            },
            onSubmitted: (_) => _checkReceiver(),
            decoration: InputDecoration(
              labelText: 'Email người nhận',
              prefixIcon: const Icon(Icons.person_search),
              isDense: true,
              suffixIcon: _checkingReceiver
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _checkReceiver,
                    ),
            ),
          ),
          if (_receiver != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.income, size: 18),
                  const SizedBox(width: 6),
                  Text('Người nhận: ${_receiver!.fullName}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _keypad() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '<'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: keys.map((k) {
        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _press(k),
          child: Center(
            child: k == '<'
                ? const Icon(Icons.backspace_outlined)
                : Text(k,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }
}
