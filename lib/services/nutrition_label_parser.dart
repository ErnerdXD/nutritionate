class ParsedNutritionLabel {
  const ParsedNutritionLabel({
    this.servingSize,
    this.calories,
    this.fat,
    this.saturatedFat,
    this.carbohydrates,
    this.sugars,
    this.fiber,
    this.protein,
    this.sodiumMg,
  });

  final double? servingSize;
  final double? calories;
  final double? fat;
  final double? saturatedFat;
  final double? carbohydrates;
  final double? sugars;
  final double? fiber;
  final double? protein;
  final double? sodiumMg;
}

class NutritionLabelParser {
  ParsedNutritionLabel parse(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.toLowerCase().replaceAll(',', '.').trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return ParsedNutritionLabel(
      servingSize: _value(lines, ['serving size', 'saiz hidangan']),
      calories: _energy(lines),
      fat: _value(
        lines,
        ['total fat', 'jumlah lemak', 'lemak'],
        exclude: ['saturated', 'tepu', 'trans'],
      ),
      saturatedFat: _value(lines, ['saturated fat', 'lemak tepu']),
      carbohydrates: _value(lines, [
        'total carbohydrate',
        'carbohydrate',
        'karbohidrat',
      ]),
      sugars: _value(lines, [
        'total sugars',
        'total sugar',
        'jumlah gula',
        'gula',
      ]),
      fiber: _value(lines, ['dietary fibre', 'dietary fiber', 'serat']),
      protein: _value(lines, ['protein']),
      sodiumMg: _sodium(lines),
    );
  }

  double? _energy(List<String> lines) {
    final line = _matchingLine(lines, [
      'energy',
      'tenaga',
      'calories',
      'kalori',
    ]);
    if (line == null) return null;
    final kcal = _numberWithUnit(line, 'kcal');
    if (kcal != null) return kcal;
    final kj = _numberWithUnit(line, 'kj');
    return kj == null ? _firstNumber(line) : kj / 4.184;
  }

  double? _sodium(List<String> lines) {
    final line = _matchingLine(lines, ['sodium', 'natrium']);
    if (line == null) return null;
    final mg = _numberWithUnit(line, 'mg');
    if (mg != null) return mg;
    final grams = _numberWithUnit(line, 'g');
    return grams == null ? _firstNumber(line) : grams * 1000;
  }

  double? _value(
    List<String> lines,
    List<String> keywords, {
    List<String> exclude = const [],
  }) {
    final line = _matchingLine(lines, keywords, exclude: exclude);
    if (line == null) return null;
    return _numberWithUnit(line, 'g') ?? _firstNumber(line);
  }

  String? _matchingLine(
    List<String> lines,
    List<String> keywords, {
    List<String> exclude = const [],
  }) {
    for (final keyword in keywords) {
      for (final line in lines) {
        if (line.contains(keyword) && !exclude.any(line.contains)) return line;
      }
    }
    return null;
  }

  double? _numberWithUnit(String line, String unit) {
    final match = RegExp('(\\d+(?:\\.\\d+)?)\\s*$unit\\b').firstMatch(line);
    return match == null ? null : double.tryParse(match.group(1)!);
  }

  double? _firstNumber(String line) {
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(line);
    return match == null ? null : double.tryParse(match.group(0)!);
  }
}
