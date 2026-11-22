import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_screen.dart';

const Color kPink = Color(0xFFE91E63);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _loading = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) _showMessage(error);
  }

  void _singIn() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập email và mật khẩu');
      return;
    }
    _run(() => _authService.signIn(email, password));
  }

  void _googleSingIn() => _run(_authService.googleSignIn);

  void _guestSignIn() => _run(_authService.signInAnonymously);

  void _forgotPassword() {
    final ctrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quên mật khẩu'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Nhập email đã đăng ký'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final error = await _authService.resetPassword(ctrl.text.trim());
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              _showMessage(error ??
                  'Đã gửi email đặt lại mật khẩu, kiểm tra hộp thư nhé');
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPink,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Appwrite App'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _forgotPassword,
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _loading ? null : _singIn,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                child: const Text('Create Account',
                    style: TextStyle(color: kPink)),
              ),
              TextButton(
                onPressed: _loading ? null : _guestSignIn,
                child: const Text('Read Messages as Guest',
                    style: TextStyle(color: kPink)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _socialButton(
                    const Text('G',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red)),
                    _googleSingIn,
                  ),
                  _socialButton(const Icon(Icons.apple, color: Colors.black),
                      () => _showMessage('Chưa hỗ trợ đăng nhập Apple')),
                  _socialButton(const Icon(Icons.facebook, color: Colors.blue),
                      () => _showMessage('Chưa hỗ trợ đăng nhập Facebook')),
                  _socialButton(const Icon(Icons.code, color: Colors.black),
                      () => _showMessage('Chưa hỗ trợ đăng nhập GitHub')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(Widget child, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: _loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(60, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: child,
    );
  }
}
