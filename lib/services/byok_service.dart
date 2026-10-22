import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ByokService {
  ByokService._();
  static final instance = ByokService._();

  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  String _keyName(User user) => 'gemini_api_key_${user.uid}';

  static bool isSupportedGeminiKey(String input) {
    final value = input.trim();
    if (value.contains(RegExp(r'\s'))) return false;
    return (value.startsWith('AIza') && value.length >= 35) ||
        (value.startsWith('AQ.') && value.length >= 30);
  }

  Future<String?> readForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final value = await _storage.read(key: _keyName(user));
    return value?.trim().isEmpty == true ? null : value?.trim();
  }

  Future<void> saveForUser(User user, String apiKey) async {
    final value = apiKey.trim();
    if (!isSupportedGeminiKey(value)) {
      throw const FormatException('Enter a valid Gemini API key.');
    }
    await _storage.write(key: _keyName(user), value: value);
  }

  Future<void> deleteForUser(User user) => _storage.delete(key: _keyName(user));
}
