import 'package:flutter/material.dart';

import '../models/food_product.dart';
import 'scanner_screen.dart';
import 'nutrition_assistant_screen.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, required this.product});

  final FoodProduct product;

  String _servingValue(double? per100g, double servingSize, String unit) {
    if (per100g == null) return '—';
    return '${(per100g * servingSize / 100).toStringAsFixed(1)} $unit';
  }

  Color _scoreColor(String score) => switch (score) {
    'A' => const Color(0xFF16834B),
    'B' => const Color(0xFF70A72D),
    'C' => const Color(0xFFF2B629),
    'D' => const Color(0xFFE77C25),
    'E' => const Color(0xFFC63D32),
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition summary')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product.imageUrl.isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFE5E9E4),
                        child: SizedBox(
                          width: 96,
                          height: 120,
                          child: Icon(Icons.fastfood, size: 42),
                        ),
                      )
                    : Image.network(
                        product.imageUrl,
                        width: 96,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(product.brand),
                    const SizedBox(height: 4),
                    Text(
                      'Source: ${product.source}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Chip(
                      backgroundColor: _scoreColor(product.nutriScore),
                      label: Text(
                        'Nutri-Score ${product.nutriScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (!product.hasNutrition) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The barcode was identified, but this source does not provide nutrition values. Check the package label.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Per 100 g',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: product.nutrients.entries.map((entry) {
                final unit = entry.key == 'Calories' ? 'kcal' : 'g';
                return ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    entry.value == null
                        ? '—'
                        : '${entry.value!.toStringAsFixed(1)} $unit',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
            ),
          ),
          if (product.servingSizeG != null && product.servingSizeG! > 0) ...[
            const SizedBox(height: 24),
            Text(
              product.servingDescription?.trim().isNotEmpty == true
                  ? product.servingDescription!
                  : '1 serving (${product.servingSizeG!.toStringAsFixed(0)} g/ml)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Estimated from ${product.servingSizeG!.toStringAsFixed(1)} g/ml',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: product.nutrients.entries.map((entry) {
                  final unit = entry.key == 'Calories' ? 'kcal' : 'g';
                  return ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text(
                      _servingValue(entry.value, product.servingSizeG!, unit),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (product.packageSizeG != null && product.packageSizeG! > 0) ...[
            const SizedBox(height: 24),
            Text(
              'Whole package',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total for ${product.packageSizeG!.toStringAsFixed(1)} g/ml',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Column(
                children: product.nutrients.entries.map((entry) {
                  final unit = entry.key == 'Calories' ? 'kcal' : 'g';
                  return ListTile(
                    dense: true,
                    title: Text(entry.key),
                    trailing: Text(
                      _servingValue(entry.value, product.packageSizeG!, unit),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Ingredients',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(product.ingredients, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan another product'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NutritionAssistantScreen(product: product),
              ),
            ),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Ask Nutrition Assistant'),
          ),
        ],
      ),
    );
  }
}
