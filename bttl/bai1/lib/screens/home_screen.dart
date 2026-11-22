import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart' show kPink;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final provider = user.isAnonymous
        ? 'Khách (Anonymous)'
        : user.providerData.map((p) => p.providerId).join(', ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPink,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                user.displayName ?? (user.isAnonymous ? 'Khách' : 'Chưa đặt tên'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(user.email ?? ''),
              const SizedBox(height: 8),
              Text('Đăng nhập bằng: $provider'),
              const SizedBox(height: 4),
              SelectableText(
                'UID: ${user.uid}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kPink),
                onPressed: () => AuthService().signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
