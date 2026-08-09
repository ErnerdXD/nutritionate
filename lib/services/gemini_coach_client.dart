import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/food_product.dart';
import 'byok_service.dart';
import 'nutrition_coach.dart';

class GeminiCoachException implements Exception {
  const GeminiCoachException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GeminiCoachClient {
  GeminiCoachClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _configuredBaseUrl();

  final http.Client _client;
  final String _baseUrl;

  static String _configuredBaseUrl() {
    const configured = String.fromEnvironment('COACH_API_URL');
    if (configured.isNotEmpty) return configured;
    return 'https://nutritionate-backend.onrender.com';
  }

  Future<String> answer({
    required String question,
    required NutritionGoal goal,
    FoodProduct? product,
    List<Map<String, String>> recentConversation = const [],
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw const GeminiCoachException(
          'Please sign in to use the assistant.',
        );
      }
      final apiKey = await ByokService.instance.readForCurrentUser();
      if (apiKey == null) {
        throw const GeminiCoachException(
          'Enable the Nutrition Assistant and add your Gemini key in first-time setup.',
        );
      }
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/coach'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-Gemini-Api-Key': apiKey,
            },
            body: jsonEncode({
              'question': question,
              'goal': goal.name,
              'recentConversation': recentConversation,
              if (product != null) 'product': _productJson(product),
            }),
          )
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw GeminiCoachException(
          body['error'] as String? ?? 'Assistant request failed.',
        );
      }
      final answer = body['answer'] as String?;
      if (answer == null || answer.trim().isEmpty) {
        throw const GeminiCoachException('The assistant returned no answer.');
      }
      final cautions = (body['cautions'] as List<dynamic>? ?? const [])
          .whereType<String>();
      final disclaimer = body['disclaimer'] as String?;
      return [
        answer,
        ...cautions,
        if (disclaimer != null && disclaimer.isNotEmpty) disclaimer,
      ].join('\n\n');
    } on GeminiCoachException {
      rethrow;
    } catch (_) {
      throw const GeminiCoachException(
        'Could not reach the nutrition assistant. Check that the backend is running.',
      );
    }
  }

  Map<String, dynamic> _productJson(FoodProduct product) => {
    'barcode': product.barcode,
    'name': product.name,
    'brand': product.brand,
    'source': product.source,
    'ingredients': product.ingredients,
    'servingSizeG': product.servingSizeG,
    'servingDescription': product.servingDescription,
    'packageSizeG': product.packageSizeG,
    'nutrients': {
      'calories': product.nutrients['Calories'],
      'fatG': product.nutrients['Fat'],
      'saturatedFatG': product.nutrients['Saturated fat'],
      'carbohydratesG': product.nutrients['Carbohydrates'],
      'sugarsG': product.nutrients['Sugars'],
      'fiberG': product.nutrients['Fiber'],
      'proteinG': product.nutrients['Protein'],
      'saltG': product.nutrients['Salt'],
    },
  };
}
