import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_preferences.dart';
import '../services/byok_service.dart';
import '../services/profile_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.user, super.key});

  final User user;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _apiKey = TextEditingController();
  bool _preferNotToSay = false;
  bool _assistantEnabled = false;
  bool _hideKey = true;
  bool _saving = false;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  String? _optionalNumber(String? value, double minimum, double maximum) {
    if (_preferNotToSay || value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    if (number == null || number < minimum || number > maximum) {
      return 'Enter a value from ${minimum.toInt()} to ${maximum.toInt()}';
    }
    return null;
  }

  Future<void> _openAiStudio() async {
    await launchUrl(
      Uri.parse('https://aistudio.google.com/app/apikey'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final existing = await ProfileService().load(widget.user);
      if (_assistantEnabled) {
        await ByokService.instance.saveForUser(widget.user, _apiKey.text);
      } else {
        await ByokService.instance.deleteForUser(widget.user);
      }
      final preferences = UserPreferences(
        goal: existing.goal,
        dietaryPattern: existing.dietaryPattern,
        allergens: existing.allergens,
        priorities: existing.priorities,
        servingBasis: existing.servingBasis,
        metricUnits: existing.metricUnits,
        darkMode: existing.darkMode,
        age: _preferNotToSay ? null : int.tryParse(_age.text.trim()),
        weightKg: _preferNotToSay ? null : double.tryParse(_weight.text.trim()),
        heightCm: _preferNotToSay ? null : double.tryParse(_height.text.trim()),
        nutritionAssistantEnabled: _assistantEnabled,
        onboardingComplete: true,
        safetyAcknowledged: existing.safetyAcknowledged,
      );
      await ProfileService().save(widget.user, preferences);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(
        'Could not save your setup. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Welcome, ${widget.user.displayName?.split(' ').first ?? 'there'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'These optional details can make nutrition guidance more relevant. You can change them later.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _age,
                enabled: !_preferNotToSay,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age (years)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _optionalNumber(value, 13, 120),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weight,
                enabled: !_preferNotToSay,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _optionalNumber(value, 20, 400),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _height,
                enabled: !_preferNotToSay,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _optionalNumber(value, 80, 250),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _preferNotToSay,
                onChanged: (value) =>
                    setState(() => _preferNotToSay = value ?? false),
                title: const Text('Prefer not to tell'),
              ),
              const Divider(height: 36),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _assistantEnabled,
                onChanged: (value) => setState(() => _assistantEnabled = value),
                title: const Text('Enable Nutrition Assistant?'),
                subtitle: const Text(
                  'Optional AI chat and photo-assisted product setup.',
                ),
              ),
              if (_assistantEnabled) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Bring your own key (BYOK)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a free Gemini API key with Google to unlock the Nutrition Assistant and AI analysis of up to 3 product or label photos. Nutritionate encrypts the key on this phone; it is not saved in our database.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openAiStudio,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Get a Gemini API key'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apiKey,
                  obscureText: _hideKey,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Paste Gemini API key',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _hideKey = !_hideKey),
                      icon: Icon(
                        _hideKey ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (!_assistantEnabled) return null;
                    if (value == null ||
                        !ByokService.isSupportedGeminiKey(value)) {
                      return 'Paste a valid Gemini API key';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _finish,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Finish setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
