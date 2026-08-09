import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_product.dart';

class LocalProductStore {
  static const _prefix = 'verified_product_';

  Future<FoodProduct?> get(String barcode) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('$_prefix$barcode');
    if (value == null) return null;
    return FoodProduct.fromStoredJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  }

  Future<void> save(FoodProduct product) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_prefix${product.barcode}',
      jsonEncode(product.toJson()),
    );
  }
}
