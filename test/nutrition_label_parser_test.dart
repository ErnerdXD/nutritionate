import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/services/nutrition_label_parser.dart';

void main() {
  test('extracts English and Malay nutrition fields', () {
    final result = NutritionLabelParser().parse('''
Saiz Hidangan 20 g
Tenaga 95 kcal
Jumlah Lemak 3.5 g
Lemak Tepu 1.2 g
Karbohidrat 14.0 g
Jumlah Gula 7.5 g
Protein 2.0 g
Natrium 80 mg
''');

    expect(result.servingSize, 20);
    expect(result.calories, 95);
    expect(result.fat, 3.5);
    expect(result.saturatedFat, 1.2);
    expect(result.carbohydrates, 14);
    expect(result.sugars, 7.5);
    expect(result.protein, 2);
    expect(result.sodiumMg, 80);
  });
}
