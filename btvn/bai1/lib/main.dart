import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/firebase_db.dart' show kDatabaseId;
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore và Storage chạy bằng emulator trên máy tính
  await FirebaseStorage.instance.useStorageEmulator('10.0.2.2', 9199);
  FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: kDatabaseId)
      .useFirestoreEmulator('10.0.2.2', 8080);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'zhippay',
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // Đã đăng nhập -> MainScreen, chưa -> WelcomeScreen
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.hasData ? const MainScreen() : const WelcomeScreen();
        },
      ),
    );
  }
}
