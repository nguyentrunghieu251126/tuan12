import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final error = await AuthService().resetPassword(_emailController.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = error == null;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.lock_reset, size: 72, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Quên mật khẩu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _sent
                    ? 'Đã gửi link đặt lại mật khẩu tới ${_emailController.text.trim()}. Hãy kiểm tra hộp thư (kể cả mục Spam).'
                    : 'Nhập email đã đăng ký, chúng tôi sẽ gửi link đặt lại mật khẩu.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _send,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_sent ? 'Gửi lại' : 'Gửi link đặt lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
