import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/wallet_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/format.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();
  late final Stream<AppUser?> _userStream = _walletService.watchCurrentUser();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _filled = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _changeAvatar() async {
    final XFile? picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 512);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await _walletService.uploadAvatar(File(picked.path));
      if (mounted) _showMessage('Đã cập nhật ảnh đại diện');
    } catch (e) {
      if (mounted) _showMessage('Lỗi upload ảnh: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _walletService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) _showMessage('Đã lưu thông tin');
    } catch (e) {
      if (mounted) _showMessage('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword(String email) async {
    final error = await _authService.resetPassword(email);
    if (!mounted) return;
    _showMessage(error ?? 'Đã gửi link đổi mật khẩu tới $email');
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok == true) await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<AppUser?>(
        stream: _userStream,
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_filled) {
            _nameController.text = user.fullName;
            _phoneController.text = user.phone;
            _filled = true;
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Hồ sơ cá nhân',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        child: _uploading
                            ? const CircularProgressIndicator()
                            : user.avatarUrl.isEmpty
                                ? Text(user.initials,
                                    style: const TextStyle(
                                        fontSize: 32,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold))
                                : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _uploading ? null : _changeAvatar,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(user.email,
                      style: const TextStyle(color: AppColors.textGrey)),
                ),
                Center(
                  child: Text('Số dư: ${formatMoney(user.balance)}',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Họ tên', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) =>
                      (v == null || !RegExp(r'^0\d{9}$').hasMatch(v.trim()))
                          ? 'Số điện thoại gồm 10 số, bắt đầu bằng 0'
                          : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Lưu thay đổi'),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_reset),
                        title: const Text('Đổi mật khẩu'),
                        subtitle: const Text('Gửi link đổi mật khẩu qua email'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _changePassword(user.email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            const Icon(Icons.logout, color: AppColors.expense),
                        title: const Text('Đăng xuất',
                            style: TextStyle(color: AppColors.expense)),
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
