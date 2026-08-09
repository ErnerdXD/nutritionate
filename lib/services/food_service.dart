import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_product.dart';
import 'local_product_store.dart';

class ProductNotFoundException implements Exception {}

class LookupUnavailableException implements Exception {
  const LookupUnavailableException(this.message);
  final String message;
}

class FoodService {
  FoodService({http.Client? client, LocalProductStore? localStore})
    : _client = client ?? http.Client(),
      _localStore = localStore ?? LocalProductStore();

  final http.Client _client;
  final LocalProductStore _localStore;
  static const _timeout = Duration(seconds: 12);

  Future<FoodProduct> getProduct(String barcode) async {
    final savedProduct = await _localStore.get(barcode);
    if (savedProduct != null) return savedProduct;

    final failures = <String>[];
    var completedLookups = 0;

    for (final lookup in <(String, Future<FoodProduct?> Function())>[
      ('Open Food Facts', () => _fromOpenFoodFacts(barcode)),
      ('USDA FoodData Central', () => _fromUsda(barcode)),
      ('UPCitemdb', () => _fromUpcItemDb(barcode)),
    ]) {
      try {
        final product = await lookup.$2();
        completedLookups++;
        if (product != null) return product;
      } catch (error) {
        failures.add('${lookup.$1}: $error');
      }
    }

    if (completedLookups == 0) {
      throw LookupUnavailableException(failures.join('\n'));
    }
    throw ProductNotFoundException();
  }

  Future<FoodProduct?> _fromOpenFoodFacts(String barcode) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {
        'fields':
            'product_name,brands,image_front_small_url,nutrition_grades,ingredients_text,nutriments,serving_size,serving_quantity,quantity,product_quantity',
      },
    );
    final response = await _client
        .get(
          uri,
          headers: const {
            'User-Agent':
                'NutriScan/1.0 (local prototype; contact via app owner)',
          },
        )
        .timeout(_timeout);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 1 || body['product'] == null) return null;
    return FoodProduct.fromJson(barcode, body);
  }

  Future<FoodProduct?> _fromUsda(String barcode) async {
    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': 'DEMO_KEY',
      'query': barcode,
      'dataType': 'Branded',
      'pageSize': '10',
    });
    final response = await _client.get(uri).timeout(_timeout);
    if ([400, 404, 429].contains(response.statusCode)) return null;
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = body['foods'] as List<dynamic>? ?? const [];
    Map<String, dynamic>? match;
    for (final food in foods.whereType<Map<String, dynamic>>()) {
      if ('${food['gtinUpc'] ?? ''}'.padLeft(13, '0') ==
          barcode.padLeft(13, '0')) {
        match = food;
        break;
      }
    }
    if (match == null) return null;

    final nutrientList = match['foodNutrients'] as List<dynamic>? ?? const [];
    double? nutrient(List<String> names) {
      for (final item in nutrientList.whereType<Map<String, dynamic>>()) {
        final name = '${item['nutrientName'] ?? ''}'.toLowerCase();
        if (names.contains(name)) return (item['value'] as num?)?.toDouble();
      }
      return null;
    }

    return FoodProduct(
      barcode: barcode,
      name: '${match['description'] ?? 'Unnamed product'}',
      brand: '${match['brandName'] ?? match['brandOwner'] ?? 'Unknown brand'}',
      imageUrl: '',
      nutriScore: '-',
      ingredients: '${match['ingredients'] ?? 'Ingredients unavailable.'}',
      nutrients: {
        'Calories': nutrient(['energy']),
        'Fat': nutrient(['total lipid (fat)', 'total fat']),
        'Saturated fat': nutrient(['fatty acids, total saturated']),
        'Carbohydrates': nutrient(['carbohydrate, by difference']),
        'Sugars': nutrient(['sugars, total including nlea', 'total sugars']),
        'Fiber': nutrient(['fiber, total dietary']),
        'Protein': nutrient(['protein']),
        'Salt': null,
      },
      source: 'USDA FoodData Central',
      servingSizeG: (match['servingSize'] as num?)?.toDouble(),
      servingDescription: match['householdServingFullText'] as String?,
      packageSizeG: null,
    );
  }

  Future<FoodProduct?> _fromUpcItemDb(String barcode) async {
    final uri = Uri.https('api.upcitemdb.com', '/prod/trial/lookup', {
      'upc': barcode,
    });
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(_timeout);
    if ([400, 404, 429].contains(response.statusCode)) return null;
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>? ?? const [];
    if (items.isEmpty || items.first is! Map<String, dynamic>) return null;
    final item = items.first as Map<String, dynamic>;
    final images = item['images'] as List<dynamic>? ?? const [];

    return FoodProduct(
      barcode: barcode,
      name: '${item['title'] ?? 'Unnamed product'}',
      brand: '${item['brand'] ?? 'Unknown brand'}',
      imageUrl: images.isEmpty ? '' : '${images.first}',
      nutriScore: '-',
      ingredients:
          'Nutrition and ingredients are unavailable from this source.',
      nutrients: const {
        'Calories': null,
        'Fat': null,
        'Saturated fat': null,
        'Carbohydrates': null,
        'Sugars': null,
        'Fiber': null,
        'Protein': null,
        'Salt': null,
      },
      source: 'UPCitemdb (identity only)',
      servingSizeG: null,
      servingDescription: null,
      packageSizeG: null,
    );
  }
}
