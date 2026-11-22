import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Database mặc định
const String kDatabaseId = '(default)';

FirebaseFirestore get appDb => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: kDatabaseId,
    );
