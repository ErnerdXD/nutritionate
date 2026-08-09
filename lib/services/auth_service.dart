import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _google = GoogleSignIn.instance;
  bool _initialized = false;

  Stream<User?> get authChanges => FirebaseAuth.instance.authStateChanges();
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _initialize() async {
    if (_initialized) return;
    await _google.initialize();
    _initialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _initialize();
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Google did not return a valid sign-in token.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _initialize();
    await Future.wait([FirebaseAuth.instance.signOut(), _google.signOut()]);
  }
}
