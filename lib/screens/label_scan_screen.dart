import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/food_product.dart';
import '../services/local_product_store.dart';
import '../services/nutrition_label_parser.dart';
import '../services/product_research_client.dart';
import '../services/scan_history_store.dart';
import 'product_screen.dart';

class LabelScanScreen extends StatefulWidget {
  const LabelScanScreen({super.key, required this.barcode});

  final String barcode;

  @override
  State<LabelScanScreen> createState() => _LabelScanScreenState();
}

class _LabelScanScreenState extends State<LabelScanScreen> {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _store = LocalProductStore();
  final _parser = NutritionLabelParser();
  final _researchClient = ProductResearchClient();

  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _servingSize = TextEditingController();
  final _servingDescription = TextEditingController();
  final _packageSize = TextEditingController();
  final _calories = TextEditingController();
  final _fat = TextEditingController();
  final _saturatedFat = TextEditingController();
  final _carbohydrates = TextEditingController();
  final _sugars = TextEditingController();
  final _fiber = TextEditingController();
  final _protein = TextEditingController();
  final _sodiumMg = TextEditingController();
  final _ingredients = TextEditingController();

  XFile? _photo;
  final _researchPhotos = <XFile>[];
  ProductResearchResult? _researchResult;
  String _rawText = '';
  bool _busy = false;
  bool _valuesPer100g = true;

  Future<void> _addResearchPhoto(ImageSource source) async {
    if (_researchPhotos.length >= 3) return;
    final photo = await _picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (photo == null || !mounted) return;
    setState(() => _researchPhotos.add(photo));
  }

  Future<void> _researchProduct() async {
    if (_researchPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product photo first.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await _researchClient.research(
        barcode: widget.barcode,
        imagePaths: _researchPhotos.map((photo) => photo.path).toList(),
      );
      final json = result.json;
      if (json['eligibleForPrefill'] != true) {
        if (!mounted) return;
        setState(() {
          _researchPhotos.clear();
          _researchResult = result;
        });
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('These photos cannot be used'),
            content: Text(
              json['rejectionReason'] as String? ??
                  'Add clear photos of packaged food and its nutrition panel.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Take new photos'),
              ),
            ],
          ),
        );
        return;
      }
      final nutrients = json['nutrients'] as Map<String, dynamic>? ?? const {};
      String value(String key) {
        final number = nutrients[key] as num?;
        return number == null ? '' : _display(number.toDouble());
      }

      _name.text = json['productName'] as String? ?? '';
      _brand.text = json['brand'] as String? ?? '';
      _ingredients.text = json['ingredients'] as String? ?? '';
      _servingSize.text = _display((json['servingSizeG'] as num?)?.toDouble());
      _servingDescription.text = json['servingDescription'] as String? ?? '';
      _packageSize.text = _display((json['packageSizeG'] as num?)?.toDouble());
      _calories.text = value('calories');
      _fat.text = value('fatG');
      _saturatedFat.text = value('saturatedFatG');
      _carbohydrates.text = value('carbohydratesG');
      _sugars.text = value('sugarsG');
      _fiber.text = value('fiberG');
      _protein.text = value('proteinG');
      _sodiumMg.text = value('sodiumMg');
      if (mounted) {
        setState(() {
          _valuesPer100g = json['valuesPer100g'] as bool? ?? true;
          _researchResult = result;
        });
      }
    } on ProductResearchException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _display(double? value) => value == null
      ? ''
      : value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  Future<void> _capture() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
      maxWidth: 2400,
    );
    if (photo == null) return;
    setState(() {
      _busy = true;
      _photo = photo;
    });
    try {
      final result = await _recognizer.processImage(
        InputImage.fromFilePath(photo.path),
      );
      final parsed = _parser.parse(result.text);
      _rawText = result.text;
      _servingSize.text = _display(parsed.servingSize);
      _calories.text = _display(parsed.calories);
      _fat.text = _display(parsed.fat);
      _saturatedFat.text = _display(parsed.saturatedFat);
      _carbohydrates.text = _display(parsed.carbohydrates);
      _sugars.text = _display(parsed.sugars);
      _fiber.text = _display(parsed.fiber);
      _protein.text = _display(parsed.protein);
      _sodiumMg.text = _display(parsed.sodiumMg);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not read label: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double? _number(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.'));
  }

  double? _per100g(TextEditingController controller) {
    final value = _number(controller);
    if (value == null || _valuesPer100g) return value;
    final serving = _number(_servingSize);
    if (serving == null || serving <= 0) return null;
    return value * 100 / serving;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the product name first.')),
      );
      return;
    }
    if (!_valuesPer100g && (_number(_servingSize) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid serving size to convert values.'),
        ),
      );
      return;
    }

    final sodiumMg = _per100g(_sodiumMg);
    final product = FoodProduct(
      barcode: widget.barcode,
      name: _name.text.trim(),
      brand: _brand.text.trim().isEmpty ? 'Unknown brand' : _brand.text.trim(),
      imageUrl: '',
      nutriScore: '-',
      ingredients: _ingredients.text.trim().isEmpty
          ? 'Ingredients not captured.'
          : _ingredients.text.trim(),
      nutrients: {
        'Calories': _per100g(_calories),
        'Fat': _per100g(_fat),
        'Saturated fat': _per100g(_saturatedFat),
        'Carbohydrates': _per100g(_carbohydrates),
        'Sugars': _per100g(_sugars),
        'Fiber': _per100g(_fiber),
        'Protein': _per100g(_protein),
        'Salt': sodiumMg == null ? null : sodiumMg / 1000 * 2.5,
      },
      source: 'Verified from package label',
      servingSizeG: _number(_servingSize),
      servingDescription: _servingDescription.text.trim().isEmpty
          ? null
          : _servingDescription.text.trim(),
      packageSizeG: _number(_packageSize),
    );
    await _store.save(product);
    await ScanHistoryStore().add(product);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
    );
  }

  @override
  void dispose() {
    _recognizer.close();
    for (final controller in [
      _name,
      _brand,
      _servingSize,
      _servingDescription,
      _packageSize,
      _calories,
      _fat,
      _saturatedFat,
      _carbohydrates,
      _sugars,
      _fiber,
      _protein,
      _sodiumMg,
      _ingredients,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan nutrition label')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Barcode ${widget.barcode}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Photograph the nutrition panel straight-on in good light. Review every detected value before saving.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AI-assisted product research',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add up to 3 clear photos: package front, barcode, and nutrition panel. AI will prefill a draft and show web sources for review.',
                  ),
                  if (_researchPhotos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _researchPhotos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_researchPhotos[index].path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              child: IconButton.filledTonal(
                                onPressed: _busy
                                    ? null
                                    : () => setState(
                                        () => _researchPhotos.removeAt(index),
                                      ),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy || _researchPhotos.length >= 3
                              ? null
                              : () => _addResearchPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy || _researchPhotos.length >= 3
                              ? null
                              : () => _addResearchPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _busy || _researchPhotos.isEmpty
                        ? null
                        : _researchProduct,
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Research and prefill draft'),
                  ),
                ],
              ),
            ),
          ),
          if (_researchResult != null) _researchSummary(),
          const SizedBox(height: 16),
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_photo!.path),
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _capture,
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(
              _photo == null ? 'Photograph nutrition panel' : 'Retake photo',
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Product name *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(
              labelText: 'Brand',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _servingDescription,
            decoration: const InputDecoration(
              labelText: 'Natural serving (for example: 1 biscuit)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _field(
            'Whole package net weight/volume',
            _packageSize,
            suffix: 'g/ml',
          ),
          if (_valuesPer100g)
            _field('Weight of that serving', _servingSize, suffix: 'g/ml'),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Per 100 g/ml')),
              ButtonSegment(value: false, label: Text('Per serving')),
            ],
            selected: {_valuesPer100g},
            onSelectionChanged: (value) =>
                setState(() => _valuesPer100g = value.first),
          ),
          const SizedBox(height: 12),
          if (!_valuesPer100g)
            _field('Serving size', _servingSize, suffix: 'g/ml'),
          if (!_valuesPer100g) const SizedBox(height: 12),
          _field('Energy', _calories, suffix: 'kcal'),
          _field('Total fat', _fat),
          _field('Saturated fat', _saturatedFat),
          _field('Carbohydrates', _carbohydrates),
          _field('Sugars', _sugars),
          _field('Fiber', _fiber),
          _field('Protein', _protein),
          _field('Sodium', _sodiumMg, suffix: 'mg'),
          TextField(
            controller: _ingredients,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Ingredients (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_rawText.isNotEmpty)
            ExpansionTile(
              title: const Text('Review text detected by OCR'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(_rawText),
                ),
              ],
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Verify and save product'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String suffix = 'g',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _researchSummary() {
    final json = _researchResult!.json;
    final exact = json['exactBarcodeMatch'] as bool? ?? false;
    final eligible = json['eligibleForPrefill'] as bool? ?? false;
    final warnings = (json['warnings'] as List<dynamic>? ?? const [])
        .whereType<String>();
    return Card(
      color: exact
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              !eligible
                  ? 'Photo set rejected'
                  : exact
                  ? 'Exact barcode corroborated'
                  : 'Exact barcode not confirmed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Confidence: ${json['confidence'] ?? 'low'}'),
            Text('${json['packagingDescription'] ?? ''}'),
            ...warnings.map((warning) => Text('• $warning')),
            if (_researchResult!.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Research sources:'),
              ..._researchResult!.sources.map(
                (source) => TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(source.url),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(source.title),
                ),
              ),
            ],
            const Text(
              'Verify every prefilled value against the physical package before saving.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
