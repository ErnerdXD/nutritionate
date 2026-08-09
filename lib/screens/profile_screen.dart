import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_preferences.dart';
import '../services/auth_service.dart';
import '../services/byok_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

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
    bool? darkMode,
    bool? safetyAcknowledged,
    int? age,
    double? weightKg,
    double? heightCm,
    bool? nutritionAssistantEnabled,
    bool? onboardingComplete,
  }) => UserPreferences(
    goal: goal ?? _preferences.goal,
    dietaryPattern: dietaryPattern ?? _preferences.dietaryPattern,
    allergens: allergens ?? _preferences.allergens,
    priorities: priorities ?? _preferences.priorities,
    servingBasis: servingBasis ?? _preferences.servingBasis,
    metricUnits: metricUnits ?? _preferences.metricUnits,
    darkMode: darkMode ?? _preferences.darkMode,
    safetyAcknowledged: safetyAcknowledged ?? _preferences.safetyAcknowledged,
    age: age ?? _preferences.age,
    weightKg: weightKg ?? _preferences.weightKg,
    heightCm: heightCm ?? _preferences.heightCm,
    nutritionAssistantEnabled:
        nutritionAssistantEnabled ?? _preferences.nutritionAssistantEnabled,
    onboardingComplete: onboardingComplete ?? _preferences.onboardingComplete,
  );

  UserPreferences _withPersonalDetails({
    required int? age,
    required double? weightKg,
    required double? heightCm,
  }) => UserPreferences(
    goal: _preferences.goal,
    dietaryPattern: _preferences.dietaryPattern,
    allergens: _preferences.allergens,
    priorities: _preferences.priorities,
    servingBasis: _preferences.servingBasis,
    metricUnits: _preferences.metricUnits,
    darkMode: _preferences.darkMode,
    safetyAcknowledged: _preferences.safetyAcknowledged,
    age: age,
    weightKg: weightKg,
    heightCm: heightCm,
    nutritionAssistantEnabled: _preferences.nutritionAssistantEnabled,
    onboardingComplete: _preferences.onboardingComplete,
  );

  Future<void> _editPersonalDetails() async {
    final age = TextEditingController(text: _preferences.age?.toString() ?? '');
    final weight = TextEditingController(
      text: _preferences.weightKg?.toString() ?? '',
    );
    final height = TextEditingController(
      text: _preferences.heightCm?.toString() ?? '',
    );
    var preferNotToSay =
        _preferences.age == null &&
        _preferences.weightKg == null &&
        _preferences.heightCm == null;
    final result = await showDialog<UserPreferences>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit personal details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: age,
                  enabled: !preferNotToSay,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age (years)'),
                ),
                TextField(
                  controller: weight,
                  enabled: !preferNotToSay,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                ),
                TextField(
                  controller: height,
                  enabled: !preferNotToSay,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: preferNotToSay,
                  onChanged: (value) =>
                      setDialogState(() => preferNotToSay = value ?? false),
                  title: const Text('Prefer not to tell'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final nextAge = preferNotToSay
                    ? null
                    : int.tryParse(age.text.trim());
                final nextWeight = preferNotToSay
                    ? null
                    : double.tryParse(weight.text.trim());
                final nextHeight = preferNotToSay
                    ? null
                    : double.tryParse(height.text.trim());
                final valid =
                    (nextAge == null || nextAge >= 13 && nextAge <= 120) &&
                    (nextWeight == null ||
                        nextWeight >= 20 && nextWeight <= 400) &&
                    (nextHeight == null ||
                        nextHeight >= 80 && nextHeight <= 250);
                if (!valid) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Check the entered values.')),
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  _withPersonalDetails(
                    age: nextAge,
                    weightKg: nextWeight,
                    heightCm: nextHeight,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    age.dispose();
    weight.dispose();
    height.dispose();
    if (result == null) return;
    setState(() {
      _preferences = result;
      _saving = true;
    });
    try {
      await _service.save(_user, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal details updated.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update personal details.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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

  Future<void> _manageAssistant() async {
    final existingKey = await ByokService.instance.readForCurrentUser();
    if (!mounted) return;
    final keyController = TextEditingController();
    var enabled = _preferences.nutritionAssistantEnabled;
    var hideKey = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nutrition Assistant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: enabled,
                  onChanged: (value) => setDialogState(() => enabled = value),
                  title: const Text('Enable assistant'),
                ),
                if (enabled) ...[
                  Text(
                    existingKey == null
                        ? 'Add your Gemini key to enable AI features.'
                        : 'A Gemini key is already encrypted on this phone. Leave this blank to keep it, or paste a new key to replace it.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://aistudio.google.com/app/apikey'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Get a Gemini API key'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyController,
                    obscureText: hideKey,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: existingKey == null
                          ? 'Paste Gemini API key'
                          : 'Replacement key (optional)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setDialogState(() => hideKey = !hideKey),
                        icon: Icon(
                          hideKey ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final enteredKey = keyController.text.trim();
                if (enabled && existingKey == null && enteredKey.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Paste a Gemini API key.')),
                  );
                  return;
                }
                if (enteredKey.isNotEmpty &&
                    !ByokService.isSupportedGeminiKey(enteredKey)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid Gemini API key.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      keyController.dispose();
      return;
    }
    setState(() => _saving = true);
    try {
      final enteredKey = keyController.text.trim();
      if (!enabled) {
        await ByokService.instance.deleteForUser(_user);
      } else if (enteredKey.isNotEmpty) {
        await ByokService.instance.saveForUser(_user, enteredKey);
      }
      final updated = _copy(nutritionAssistantEnabled: enabled);
      await _service.save(_user, updated);
      if (mounted) {
        setState(() => _preferences = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Nutrition Assistant enabled.'
                  : 'Nutrition Assistant disabled and key removed.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the assistant.')),
        );
      }
    } finally {
      keyController.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _saving = true);
    try {
      await AuthService.instance.signOut();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign out. Try again.')),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Personal details'),
                  subtitle: Text(
                    _preferences.age == null &&
                            _preferences.weightKg == null &&
                            _preferences.heightCm == null
                        ? 'Prefer not to tell'
                        : [
                            if (_preferences.age != null)
                              '${_preferences.age} years',
                            if (_preferences.weightKg != null)
                              '${_preferences.weightKg} kg',
                            if (_preferences.heightCm != null)
                              '${_preferences.heightCm} cm',
                          ].join(' · '),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Nutrition Assistant'),
                  subtitle: Text(
                    _preferences.nutritionAssistantEnabled
                        ? 'Enabled with your encrypted Gemini key'
                        : 'Not enabled',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _saving ? null : _manageAssistant,
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _editPersonalDetails,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit age, weight & height'),
                ),
                const SizedBox(height: 20),
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark mode'),
                  subtitle: const Text(
                    'Switch between light and dark appearance.',
                  ),
                  value: _preferences.darkMode,
                  onChanged: (value) {
                    setState(() => _preferences = _copy(darkMode: value));
                    ThemeService.instance.apply(darkMode: value);
                  },
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
                  onPressed: _saving ? null : _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
    );
  }
}
