import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/product_list_screen.dart';
import 'services/product_service.dart' show kDatabaseId;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Storage và Firestore chạy bằng emulator trên máy tính
  await FirebaseStorage.instance.useStorageEmulator('10.0.2.2', 9199);
  FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: kDatabaseId)
      .useFirestoreEmulator('10.0.2.2', 8080);

  // Đăng nhập ẩn danh
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Products',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6C4EF2),
        useMaterial3: true,
      ),
      home: const ProductListScreen(),
    );
  }
}
