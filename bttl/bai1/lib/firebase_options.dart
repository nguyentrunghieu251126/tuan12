import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBr_d7eXwbk57EU-kmOCxym_pvpjHkvaV0',
    appId: '1:84257518370:web:cb81c7cee4bd59b57a6b7b',
    messagingSenderId: '84257518370',
    projectId: 'chuong7-flutter',
    authDomain: 'chuong7-flutter.firebaseapp.com',
    storageBucket: 'chuong7-flutter.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDx3QO7ELUQ2fq-WJHBpFHfdBuH7ZR2bCI',
    appId: '1:84257518370:android:2d878a6fbfca01417a6b7b',
    messagingSenderId: '84257518370',
    projectId: 'chuong7-flutter',
    storageBucket: 'chuong7-flutter.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBHh4NO9s3f2hBF7UONfLY89k6OVzUOuxw',
    appId: '1:84257518370:ios:1b9f6640343257607a6b7b',
    messagingSenderId: '84257518370',
    projectId: 'chuong7-flutter',
    storageBucket: 'chuong7-flutter.firebasestorage.app',
    iosClientId:
        '84257518370-6q90kqq0egt9j9oj2dj6kj5cu6fk5sin.apps.googleusercontent.com',
    iosBundleId: 'com.example.bai1',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBHh4NO9s3f2hBF7UONfLY89k6OVzUOuxw',
    appId: '1:84257518370:ios:1b9f6640343257607a6b7b',
    messagingSenderId: '84257518370',
    projectId: 'chuong7-flutter',
    storageBucket: 'chuong7-flutter.firebasestorage.app',
    iosClientId:
        '84257518370-6q90kqq0egt9j9oj2dj6kj5cu6fk5sin.apps.googleusercontent.com',
    iosBundleId: 'com.example.bai1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBr_d7eXwbk57EU-kmOCxym_pvpjHkvaV0',
    appId: '1:84257518370:web:8f96baaea10a644a7a6b7b',
    messagingSenderId: '84257518370',
    projectId: 'chuong7-flutter',
    authDomain: 'chuong7-flutter.firebaseapp.com',
    storageBucket: 'chuong7-flutter.firebasestorage.app',
  );
}
