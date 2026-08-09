import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_product.dart';

class ScanHistoryEntry {
  const ScanHistoryEntry({required this.product, required this.scannedAt});

  final FoodProduct product;
  final DateTime scannedAt;

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'scannedAt': scannedAt.toIso8601String(),
  };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScanHistoryEntry(
      product: FoodProduct.fromStoredJson(
        json['product'] as Map<String, dynamic>,
      ),
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
}

class ScanHistoryStore {
  static String keyForUser(String uid) => 'scan_history_v2_$uid';

  String? get _key {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : keyForUser(uid);
  }

  Future<List<ScanHistoryEntry>> getAll() async {
    final key = _key;
    if (key == null) return const [];
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(key) ?? const [];
    return raw
        .map(
          (value) => ScanHistoryEntry.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> add(FoodProduct product) async {
    final key = _key;
    if (key == null) return;
    final preferences = await SharedPreferences.getInstance();
    final history = preferences.getStringList(key) ?? <String>[];
    history.insert(
      0,
      jsonEncode(
        ScanHistoryEntry(product: product, scannedAt: DateTime.now()).toJson(),
      ),
    );
    if (history.length > 50) history.removeRange(50, history.length);
    await preferences.setStringList(key, history);
  }

  Future<void> clear() async {
    final key = _key;
    if (key == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }
}
