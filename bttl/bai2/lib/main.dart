import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Dùng Storage Emulator chạy trên máy tính (không cần gói Blaze).
  // Máy ảo Android: 10.0.2.2 | Điện thoại thật: đổi thành IP máy tính
  await FirebaseStorage.instance.useStorageEmulator('10.0.2.2', 9199);
  checkFirebaseConnected();

  // Storage rule yêu cầu đăng nhập -> đăng nhập ẩn danh
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const MyApp());
}

void checkFirebaseConnected() async {
  bool isConnected = Firebase.apps.isNotEmpty;
  debugPrint('Firebase connected: $isConnected');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Upload',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF42B4F5),
        useMaterial3: true,
      ),
      home: const UploadScreen(),
    );
  }
}
