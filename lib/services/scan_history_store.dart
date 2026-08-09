import 'dart:convert';

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
  static const _key = 'scan_history_v1';

  Future<List<ScanHistoryEntry>> getAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_key) ?? const [];
    return raw
        .map(
          (value) => ScanHistoryEntry.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> add(FoodProduct product) async {
    final preferences = await SharedPreferences.getInstance();
    final history = preferences.getStringList(_key) ?? <String>[];
    history.insert(
      0,
      jsonEncode(
        ScanHistoryEntry(product: product, scannedAt: DateTime.now()).toJson(),
      ),
    );
    if (history.length > 50) history.removeRange(50, history.length);
    await preferences.setStringList(_key, history);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
