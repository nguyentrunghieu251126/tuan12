import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _ggSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final Logger _logger = Logger();

  User? get currentUser => _auth.currentUser;

  Future<String?> register(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user!.updateDisplayName(name);
      _logger.i("User registered: ${userCredential.user!.email}");
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e("Error: ${e.message}");
      return _message(e);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      _logger.i("User logged in: ${userCredential.user!.email}");
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e("Error: ${e.message}");
      return _message(e);
    }
  }

  Future<String?> googleSignIn() async {
    try {
      GoogleSignInAccount? googleUser = await _ggSignIn.signIn();
      if (googleUser == null) {
        _logger.i("Huy dang nhap roi");
        return 'Bạn đã hủy đăng nhập Google';
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      _logger.i("Access token: ${googleAuth.accessToken}");
      _logger.i("ID token: ${googleAuth.idToken}");

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      _logger.i("User signed in: ${userCredential.user!.displayName}");
      _logger.i("Email: ${userCredential.user!.email}");
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e("Error during Google Sign-In: ${e.message}");
      return _message(e);
    } catch (e) {
      _logger.e("Error during Google Sign-In: $e");
      return 'Đăng nhập Google thất bại: $e';
    }
  }

  Future<String?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      _logger.i("Guest logged in: ${userCredential.user!.uid}");
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e("Error: ${e.message}");
      return _message(e);
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.i("Reset email sent to $email");
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e("Error: ${e.message}");
      return _message(e);
    }
  }

  Future<void> signOut() async {
    await _ggSignIn.signOut();
    await _auth.signOut();
    _logger.i("User signed out");
  }

  String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu phải có ít nhất 6 ký tự';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, vui lòng thử lại sau';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật trên Firebase';
      default:
        return e.message ?? 'Đã có lỗi xảy ra';
    }
  }
}
