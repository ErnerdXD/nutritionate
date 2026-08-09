import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  late final User _user;
  UserPreferences _preferences = const UserPreferences();
  bool _loading = true;
  bool _saving = false;

  static const goals = [
    'Balanced eating',
    'Lower sugar',
    'Higher protein',
    'Lower salt',
    'Weight awareness',
  ];
  static const diets = [
    'No specific pattern',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Halal',
    'Kosher',
  ];
  static const allergens = [
    'Milk',
    'Eggs',
    'Fish',
    'Shellfish',
    'Peanuts',
    'Tree nuts',
    'Wheat',
    'Soy',
    'Sesame',
  ];
  static const priorities = [
    'Calories',
    'Protein',
    'Sugar',
    'Salt',
    'Fiber',
    'Saturated fat',
  ];

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _service.load(_user);
      if (mounted) setState(() => _preferences = value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load cloud preferences.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  UserPreferences _copy({
    String? goal,
    String? dietaryPattern,
    List<String>? allergens,
    List<String>? priorities,
    String? servingBasis,
    bool? metricUnits,
    bool? safetyAcknowledged,
  }) => UserPreferences(
    goal: goal ?? _preferences.goal,
    dietaryPattern: dietaryPattern ?? _preferences.dietaryPattern,
    allergens: allergens ?? _preferences.allergens,
    priorities: priorities ?? _preferences.priorities,
    servingBasis: servingBasis ?? _preferences.servingBasis,
    metricUnits: metricUnits ?? _preferences.metricUnits,
    safetyAcknowledged: safetyAcknowledged ?? _preferences.safetyAcknowledged,
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.save(_user, _preferences);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Preferences saved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save preferences.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & preferences')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: _user.photoURL == null
                          ? null
                          : NetworkImage(_user.photoURL!),
                      child: _user.photoURL == null
                          ? const Icon(Icons.person, size: 34)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user.displayName ?? 'Nutritionate user',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(_user.email ?? ''),
                          const Text('Signed in with Google'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                DropdownButtonFormField<String>(
                  initialValue: _preferences.goal,
                  decoration: const InputDecoration(
                    labelText: 'Primary nutrition goal',
                    border: OutlineInputBorder(),
                  ),
                  items: goals
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _preferences = _copy(goal: value));
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _preferences.dietaryPattern,
                  decoration: const InputDecoration(
                    labelText: 'Dietary pattern',
                    border: OutlineInputBorder(),
                  ),
                  items: diets
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(
                        () => _preferences = _copy(dietaryPattern: value),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Allergens to highlight',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'These are warnings only—always check the current package label.',
                ),
                Wrap(
                  spacing: 8,
                  children: allergens.map((value) {
                    final selected = _preferences.allergens.contains(value);
                    return FilterChip(
                      label: Text(value),
                      selected: selected,
                      onSelected: (enabled) {
                        final values = [..._preferences.allergens];
                        enabled ? values.add(value) : values.remove(value);
                        setState(() => _preferences = _copy(allergens: values));
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Nutrients to prioritize',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: priorities.map((value) {
                    final selected = _preferences.priorities.contains(value);
                    return FilterChip(
                      label: Text(value),
                      selected: selected,
                      onSelected: (enabled) {
                        final values = [..._preferences.priorities];
                        enabled ? values.add(value) : values.remove(value);
                        setState(
                          () => _preferences = _copy(priorities: values),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Per serving',
                      label: Text('Per serving'),
                    ),
                    ButtonSegment(
                      value: 'Per 100 g/ml',
                      label: Text('Per 100 g/ml'),
                    ),
                  ],
                  selected: {_preferences.servingBasis},
                  onSelectionChanged: (value) => setState(
                    () => _preferences = _copy(servingBasis: value.first),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use metric units'),
                  value: _preferences.metricUnits,
                  onChanged: (value) =>
                      setState(() => _preferences = _copy(metricUnits: value)),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _preferences.safetyAcknowledged,
                  onChanged: (value) => setState(
                    () => _preferences = _copy(
                      safetyAcknowledged: value ?? false,
                    ),
                  ),
                  title: const Text(
                    'I understand this is general guidance, not medical advice.',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save preferences'),
                ),
                TextButton.icon(
                  onPressed: _saving ? null : AuthService.instance.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
    );
  }
}
