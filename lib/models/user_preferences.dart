class UserPreferences {
  const UserPreferences({
    this.goal = 'Balanced eating',
    this.dietaryPattern = 'No specific pattern',
    this.allergens = const [],
    this.priorities = const ['Calories', 'Protein', 'Sugar', 'Salt'],
    this.servingBasis = 'Per serving',
    this.metricUnits = true,
    this.safetyAcknowledged = false,
  });

  final String goal;
  final String dietaryPattern;
  final List<String> allergens;
  final List<String> priorities;
  final String servingBasis;
  final bool metricUnits;
  final bool safetyAcknowledged;

  Map<String, dynamic> toJson() => {
    'goal': goal,
    'dietaryPattern': dietaryPattern,
    'allergens': allergens,
    'priorities': priorities,
    'servingBasis': servingBasis,
    'metricUnits': metricUnits,
    'safetyAcknowledged': safetyAcknowledged,
  };

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPreferences();
    List<String> strings(String key, List<String> fallback) =>
        (json[key] as List<dynamic>?)?.whereType<String>().toList() ?? fallback;
    return UserPreferences(
      goal: json['goal'] as String? ?? 'Balanced eating',
      dietaryPattern:
          json['dietaryPattern'] as String? ?? 'No specific pattern',
      allergens: strings('allergens', const []),
      priorities: strings('priorities', const [
        'Calories',
        'Protein',
        'Sugar',
        'Salt',
      ]),
      servingBasis: json['servingBasis'] as String? ?? 'Per serving',
      metricUnits: json['metricUnits'] as bool? ?? true,
      safetyAcknowledged: json['safetyAcknowledged'] as bool? ?? false,
    );
  }
}
