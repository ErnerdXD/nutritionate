import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/models/food_product.dart';
import 'package:nutriscan/services/nutrition_coach.dart';

void main() {
  const product = FoodProduct(
    barcode: '96385074',
    name: 'Test biscuits',
    brand: 'Test brand',
    imageUrl: '',
    nutriScore: '-',
    ingredients: 'Wheat flour, sugar',
    nutrients: {
      'Calories': 500,
      'Fat': 20,
      'Saturated fat': 10,
      'Carbohydrates': 70,
      'Sugars': 30,
      'Fiber': 3,
      'Protein': 6,
      'Salt': 1,
    },
    source: 'Test',
    servingSizeG: 20,
    servingDescription: '1 biscuit',
    packageSizeG: 100,
  );

  test('calculates a natural serving from verified per-100g values', () {
    final answer = NutritionCoach().answer(
      question: 'What is in one serving?',
      goal: NutritionGoal.balanced,
      product: product,
    );

    expect(answer, contains('100.0 kcal'));
    expect(answer, contains('1.2 g'));
  });

  test('does not claim allergy safety', () {
    final answer = NutritionCoach().answer(
      question: 'Is it allergy-safe?',
      goal: NutritionGoal.balanced,
      product: product,
    );

    expect(answer, contains('cannot confirm allergy safety'));
  });

  test('answers general questions without a scanned product', () {
    final answer = NutritionCoach().answer(
      question: 'How can I eat less sugar?',
      goal: NutritionGoal.lowerSugar,
    );

    expect(answer, contains('compare sugar per serving'));
    expect(answer, isNot(contains('most useful answer after you scan')));
  });
}
