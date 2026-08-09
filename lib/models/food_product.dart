class FoodProduct {
  const FoodProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.nutriScore,
    required this.ingredients,
    required this.nutrients,
    required this.source,
    this.servingSizeG,
    this.servingDescription,
    this.packageSizeG,
  });

  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String nutriScore;
  final String ingredients;
  final Map<String, double?> nutrients;
  final String source;
  final double? servingSizeG;
  final String? servingDescription;
  final double? packageSizeG;

  bool get hasNutrition => nutrients.values.any((value) => value != null);

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'brand': brand,
    'imageUrl': imageUrl,
    'nutriScore': nutriScore,
    'ingredients': ingredients,
    'nutrients': nutrients,
    'source': source,
    'servingSizeG': servingSizeG,
    'servingDescription': servingDescription,
    'packageSizeG': packageSizeG,
  };

  factory FoodProduct.fromStoredJson(Map<String, dynamic> json) {
    final storedNutrients =
        json['nutrients'] as Map<String, dynamic>? ?? const {};
    return FoodProduct(
      barcode: '${json['barcode'] ?? ''}',
      name: '${json['name'] ?? 'Unnamed product'}',
      brand: '${json['brand'] ?? 'Unknown brand'}',
      imageUrl: '${json['imageUrl'] ?? ''}',
      nutriScore: '${json['nutriScore'] ?? '-'}',
      ingredients: '${json['ingredients'] ?? 'Ingredients unavailable.'}',
      nutrients: storedNutrients.map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble()),
      ),
      source: '${json['source'] ?? 'Saved nutrition label'}',
      servingSizeG: (json['servingSizeG'] as num?)?.toDouble(),
      servingDescription: json['servingDescription'] as String?,
      packageSizeG: (json['packageSizeG'] as num?)?.toDouble(),
    );
  }

  factory FoodProduct.fromJson(String barcode, Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? const {};
    final nutriments =
        product['nutriments'] as Map<String, dynamic>? ?? const {};

    double? number(String key) => (nutriments[key] as num?)?.toDouble();

    return FoodProduct(
      barcode: barcode,
      name: (product['product_name'] as String?)?.trim().isNotEmpty == true
          ? product['product_name'] as String
          : 'Unnamed product',
      brand: product['brands'] as String? ?? 'Unknown brand',
      imageUrl: product['image_front_small_url'] as String? ?? '',
      nutriScore: (product['nutrition_grades'] as String? ?? '-').toUpperCase(),
      ingredients:
          product['ingredients_text'] as String? ??
          'Ingredients have not been added yet.',
      nutrients: {
        'Calories': number('energy-kcal_100g'),
        'Fat': number('fat_100g'),
        'Saturated fat': number('saturated-fat_100g'),
        'Carbohydrates': number('carbohydrates_100g'),
        'Sugars': number('sugars_100g'),
        'Fiber': number('fiber_100g'),
        'Protein': number('proteins_100g'),
        'Salt': number('salt_100g'),
      },
      source: 'Open Food Facts',
      servingSizeG: (product['serving_quantity'] as num?)?.toDouble(),
      servingDescription: product['serving_size'] as String?,
      packageSizeG: _packageSize(product),
    );
  }

  static double? _packageSize(Map<String, dynamic> product) {
    final quantity = product['product_quantity'];
    if (quantity is num) return quantity.toDouble();
    final text = '${product['quantity'] ?? ''}'.toLowerCase().replaceAll(
      ',',
      '.',
    );
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*(kg|g|ml|l)\b').firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(match.group(1)!);
    if (value == null) return null;
    return switch (match.group(2)) {
      'kg' || 'l' => value * 1000,
      _ => value,
    };
  }
}
