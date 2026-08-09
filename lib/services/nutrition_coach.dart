import '../models/food_product.dart';

enum NutritionGoal {
  balanced('Balanced eating'),
  lowerSugar('Lower sugar'),
  higherProtein('Higher protein'),
  lowerSalt('Lower salt'),
  weightAwareness('Weight awareness');

  const NutritionGoal(this.label);
  final String label;
}

class NutritionCoach {
  String answer({
    required String question,
    required NutritionGoal goal,
    FoodProduct? product,
  }) {
    final lower = question.toLowerCase();
    if (product == null) {
      return _generalAnswer(lower, goal);
    }
    if (!product.hasNutrition) {
      return 'I can identify ${product.name}, but its nutrition values are missing. Scan and verify the package nutrition label before relying on an assessment.';
    }
    if (lower.contains('allerg') || lower.contains('safe for')) {
      return 'I cannot confirm allergy safety. Read the package allergen statement every time and check for “may contain” warnings. The recorded ingredients say: ${product.ingredients}';
    }
    if (lower.contains('whole') || lower.contains('package')) {
      return _wholePackage(product);
    }
    if (lower.contains('serving') ||
        lower.contains('one biscuit') ||
        lower.contains('one piece')) {
      return _serving(product);
    }
    if (lower.contains('healthy') ||
        lower.contains('good') ||
        lower.contains('advice')) {
      return _goalAssessment(product, goal);
    }
    return '${_goalAssessment(product, goal)}\n\nYou can also ask about one serving, the whole package, sugar, protein, salt, calories, or the recorded ingredients.';
  }

  String _generalAnswer(String question, NutritionGoal goal) {
    if (question.contains('allerg') || question.contains('safe')) {
      return 'For allergies, never rely on an assistant alone. Check the current package ingredients and “may contain” statement, and follow advice from a qualified clinician.';
    }
    if (question.contains('protein')) {
      return 'For a higher-protein pattern, compare protein per serving rather than per package, and consider foods such as eggs, fish, poultry, tofu, tempeh, beans, lentils, dairy, or suitable alternatives.';
    }
    if (question.contains('sugar')) {
      return 'For lower sugar, compare sugar per serving, check how many servings you actually eat, and watch for sweetened drinks because they can add sugar quickly.';
    }
    if (question.contains('salt') || question.contains('sodium')) {
      return 'For lower salt, compare sodium or salt per serving and consider the total from sauces, seasoning, snacks, and prepared foods across the day.';
    }
    if (question.contains('calorie') || question.contains('weight')) {
      return 'For weight awareness, portions and eating frequency matter. Use package calories per serving, then consider hunger, protein, fiber, drinks, and your overall daily pattern.';
    }
    if (question.contains('healthy') || question.contains('eat')) {
      return 'A practical healthy pattern emphasizes varied minimally processed foods, vegetables and fruit, suitable protein sources, whole grains, and portions that fit your needs. No single food determines whether your diet is healthy.';
    }
    return 'For your ${goal.label.toLowerCase()} goal, I can answer general questions now. For precise product advice, scan a product first so I can use verified serving and nutrition values.';
  }

  String _goalAssessment(FoodProduct product, NutritionGoal goal) {
    final basis = product.servingSizeG != null && product.servingSizeG! > 0
        ? product.servingSizeG!
        : 100.0;
    final basisLabel = product.servingSizeG != null && product.servingSizeG! > 0
        ? (product.servingDescription?.trim().isNotEmpty == true
              ? product.servingDescription!
              : 'one ${basis.toStringAsFixed(0)} g/ml serving')
        : '100 g/ml';
    final calories = _amount(product, 'Calories', basis);
    final sugars = _amount(product, 'Sugars', basis);
    final protein = _amount(product, 'Protein', basis);
    final salt = _amount(product, 'Salt', basis);

    final detail = switch (goal) {
      NutritionGoal.lowerSugar =>
        'For your lower-sugar goal, focus on the recorded ${_format(sugars, 'g')} of sugar in $basisLabel and compare it with what else you eat that day.',
      NutritionGoal.higherProtein =>
        'For your higher-protein goal, $basisLabel provides ${_format(protein, 'g')} of protein. Consider whether that is meaningful for the size of the serving.',
      NutritionGoal.lowerSalt =>
        'For your lower-salt goal, $basisLabel contains ${_format(salt, 'g')} of estimated salt. Sodium-based salt values are conversions and should be checked against the label.',
      NutritionGoal.weightAwareness =>
        'For weight awareness, $basisLabel provides ${_format(calories, 'kcal')}. Portion size and eating frequency matter more than judging the product by one number.',
      NutritionGoal.balanced =>
        '$basisLabel provides ${_format(calories, 'kcal')}, ${_format(protein, 'g')} protein, ${_format(sugars, 'g')} sugar, and ${_format(salt, 'g')} estimated salt.',
    };
    return '$detail “Healthy” depends on your overall diet, portion, frequency, and health needs—not one product alone.';
  }

  String _serving(FoodProduct product) {
    final size = product.servingSizeG;
    if (size == null || size <= 0) {
      return 'This product does not have a verified serving weight yet. Add the weight of one biscuit or piece from the package before calculating a natural serving.';
    }
    final label = product.servingDescription?.trim().isNotEmpty == true
        ? product.servingDescription!
        : 'One serving (${size.toStringAsFixed(1)} g/ml)';
    return '$label contains about ${_format(_amount(product, 'Calories', size), 'kcal')}, ${_format(_amount(product, 'Protein', size), 'g')} protein, ${_format(_amount(product, 'Carbohydrates', size), 'g')} carbohydrates, ${_format(_amount(product, 'Sugars', size), 'g')} sugar, and ${_format(_amount(product, 'Fat', size), 'g')} fat.';
  }

  String _wholePackage(FoodProduct product) {
    final size = product.packageSizeG;
    if (size == null || size <= 0) {
      return 'The package net weight is not verified yet. Enter the printed net weight/volume to calculate totals for the whole product.';
    }
    return 'The whole ${size.toStringAsFixed(1)} g/ml package contains about ${_format(_amount(product, 'Calories', size), 'kcal')}, ${_format(_amount(product, 'Protein', size), 'g')} protein, ${_format(_amount(product, 'Carbohydrates', size), 'g')} carbohydrates, ${_format(_amount(product, 'Sugars', size), 'g')} sugar, and ${_format(_amount(product, 'Fat', size), 'g')} fat.';
  }

  double? _amount(FoodProduct product, String nutrient, double amount) {
    final per100 = product.nutrients[nutrient];
    return per100 == null ? null : per100 * amount / 100;
  }

  String _format(double? value, String unit) {
    return value == null
        ? 'an unavailable amount'
        : '${value.toStringAsFixed(1)} $unit';
  }
}
