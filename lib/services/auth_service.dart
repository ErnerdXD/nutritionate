import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _google = GoogleSignIn.instance;
  bool _initialized = false;
  bool _signedInDuringThisRun = false;
  bool _suppressWelcomeBack = false;
  bool _welcomeShownThisRun = false;
  String? _pendingLoginMessage;

  Stream<User?> get authChanges => FirebaseAuth.instance.authStateChanges();
  User? get currentUser => FirebaseAuth.instance.currentUser;
  bool get signedInDuringThisRun => _signedInDuringThisRun;

  String? takePendingLoginMessage() {
    final value = _pendingLoginMessage;
    _pendingLoginMessage = null;
    return value;
  }

  bool takeWelcomeBack() {
    if (_suppressWelcomeBack || _welcomeShownThisRun) {
      return false;
    }
    _welcomeShownThisRun = true;
    return true;
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    await _google.initialize();
    _initialized = true;
  }

  Future<UserCredential> signInWithGoogle({bool loginOnly = false}) async {
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
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    if (loginOnly) {
      final user = result.user!;
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final preferences = profile.data()?['preferences'];
      final registered =
          profile.exists &&
          preferences is Map<String, dynamic> &&
          preferences['onboardingComplete'] == true;
      if (!registered) {
        if (result.additionalUserInfo?.isNewUser == true) {
          await user.delete();
        } else {
          await FirebaseAuth.instance.signOut();
        }
        try {
          await _google.signOut();
        } catch (_) {}
        _pendingLoginMessage =
            'This Google account does not have a completed Nutritionate account yet. Please register using Sign up with Google.';
        throw FirebaseAuthException(
          code: 'nutritionate-account-not-found',
          message: 'This account does not exist yet. Please sign up first.',
        );
      }
    }
    _signedInDuringThisRun = true;
    _suppressWelcomeBack = result.additionalUserInfo?.isNewUser == true;
    _welcomeShownThisRun = false;
    return result;
  }

  Future<void> signOut() async {
    try {
      // Firebase controls the app session, so always clear it first. A stale
      // Google provider session must never prevent the user from signing out.
      await FirebaseAuth.instance.signOut();
      try {
        await _initialize();
        await _google.signOut();
      } catch (_) {
        // Firebase is already signed out; Google will show account selection
        // again if its local provider state could not be cleared.
      }
    } finally {
      _signedInDuringThisRun = false;
      _suppressWelcomeBack = false;
      _welcomeShownThisRun = false;
    }
  }
}
