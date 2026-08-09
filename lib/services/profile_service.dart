import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_preferences.dart';

class ProfileService {
  DocumentReference<Map<String, dynamic>> _document(User user) =>
      FirebaseFirestore.instance.collection('users').doc(user.uid);

  Future<UserPreferences> load(User user) async {
    final snapshot = await _document(user).get();
    return UserPreferences.fromJson(snapshot.data()?['preferences']);
  }

  Future<void> save(User user, UserPreferences preferences) =>
      _document(user).set({
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'preferences': preferences.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<bool> onboardingComplete(User user) async {
    final preferences = await load(user);
    return preferences.onboardingComplete;
  }
}
