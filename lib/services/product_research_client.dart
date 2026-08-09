import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'byok_service.dart';

class ResearchSource {
  const ResearchSource({required this.title, required this.url});
  final String title;
  final String url;
}

class ProductResearchResult {
  const ProductResearchResult({required this.json, required this.sources});
  final Map<String, dynamic> json;
  final List<ResearchSource> sources;
}

class ProductResearchException implements Exception {
  const ProductResearchException(this.message);
  final String message;
}

class ProductResearchClient {
  static String get _baseUrl {
    const configured = String.fromEnvironment('COACH_API_URL');
    if (configured.isNotEmpty) return configured;
    return 'https://nutritionate-backend.onrender.com';
  }

  Future<ProductResearchResult> research({
    required String barcode,
    required List<String> imagePaths,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw const ProductResearchException(
          'Please sign in to research a product.',
        );
      }
      final apiKey = await ByokService.instance.readForCurrentUser();
      if (apiKey == null) {
        throw const ProductResearchException(
          'Enable the Nutrition Assistant and add your Gemini key in first-time setup.',
        );
      }
      final images = <Map<String, String>>[];
      for (final path in imagePaths.take(3)) {
        final bytes = await File(path).readAsBytes();
        if (bytes.length > 2_500_000) {
          throw const ProductResearchException(
            'One photo is still too large. Retake it closer to the package.',
          );
        }
        images.add({
          'mimeType': path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg',
          'data': base64Encode(bytes),
        });
      }
      final response = await http
          .post(
            Uri.parse('$_baseUrl/v1/product-research'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-Gemini-Api-Key': apiKey,
            },
            body: jsonEncode({'barcode': barcode, 'images': images}),
          )
          .timeout(const Duration(seconds: 90));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw ProductResearchException(
          body['error'] as String? ?? 'Product research failed.',
        );
      }
      final sources = (body['sources'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (source) => ResearchSource(
              title: source['title'] as String? ?? 'Source',
              url: source['url'] as String? ?? '',
            ),
          )
          .where((source) => source.url.isNotEmpty)
          .toList();
      return ProductResearchResult(json: body, sources: sources);
    } on ProductResearchException {
      rethrow;
    } catch (_) {
      throw const ProductResearchException(
        'Could not research this product. Check the backend and your connection.',
      );
    }
  }
}
