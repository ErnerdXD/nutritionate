import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/food_service.dart';
import '../services/barcode_validator.dart';
import '../services/scan_history_store.dart';
import 'label_scan_screen.dart';
import 'product_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  final _foodService = FoodService();
  final _picker = ImagePicker();
  bool _busy = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (_busy || code == null || code.isEmpty) return;
    await _handleCode(code);
  }

  Future<void> _handleCode(String code) async {
    setState(() => _busy = true);
    await _controller.stop();

    if (!BarcodeValidator.isValidGtin(code)) {
      _showInvalidBarcode(code);
      return;
    }

    try {
      final product = await _foodService.getProduct(code);
      await ScanHistoryStore().add(product);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
      );
    } on ProductNotFoundException {
      _showNotFound(code);
    } on LookupUnavailableException catch (error) {
      debugPrint(error.message);
      _showError(
        'Databases unavailable',
        'The product services could not be reached. Check your connection and try again.',
      );
    } catch (error) {
      debugPrint('Unexpected product lookup error: $error');
      _showError(
        'Could not check product',
        'Something went wrong while checking this barcode. Please try again.',
      );
    }
  }

  Future<void> _scanUploaded({required bool cropFirst}) async {
    if (_busy) return;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (image == null) return;

    String path = image.path;
    if (cropFirst) {
      if (!mounted) return;
      final colors = Theme.of(context).colorScheme;
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop barcode area',
            toolbarColor: colors.primary,
            toolbarWidgetColor: colors.onPrimary,
            lockAspectRatio: false,
          ),
        ],
      );
      if (cropped == null) return;
      path = cropped.path;
    }

    setState(() => _busy = true);
    await _controller.stop();
    try {
      final capture = await _controller.analyzeImage(path);
      String? code;
      for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
        if (barcode.rawValue?.isNotEmpty == true) {
          code = barcode.rawValue;
          break;
        }
      }
      if (code == null) {
        _showUploadNotRead();
        return;
      }
      setState(() => _busy = false);
      await _handleCode(code);
    } catch (error) {
      debugPrint('Uploaded barcode scan failed: $error');
      _showUploadNotRead();
    }
  }

  void _showUploadNotRead() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No barcode found'),
        content: const Text(
          'Try a sharper image, or crop closely around the complete barcode without cutting off any lines or numbers.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _busy = false);
              _controller.start();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload barcode image',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Automatic scan checks the whole image. Manual crop works better when the barcode is small or surrounded by other text.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _scanUploaded(cropFirst: false);
                },
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Scan whole image automatically'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _scanUploaded(cropFirst: true);
                },
                icon: const Icon(Icons.crop),
                label: const Text('Crop barcode area manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvalidBarcode(String barcode) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Barcode not read correctly'),
        content: Text(
          '$barcode does not have a valid barcode check digit. Clean the barcode, improve the lighting, and scan it again.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _busy = false);
              _controller.start();
            },
            child: const Text('Scan again'),
          ),
        ],
      ),
    );
  }

  void _showNotFound(String barcode) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Product not found'),
        content: const Text(
          'No database has this barcode. Photograph the package nutrition panel to add an accurate verified record.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _busy = false);
              _controller.start();
            },
            child: const Text('Scan again'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => LabelScanScreen(barcode: barcode),
                ),
              );
            },
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Scan label'),
          ),
        ],
      ),
    );
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _busy = false);
              _controller.start();
            },
            child: const Text('Scan again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: const Text('Scan barcode'),
        actions: [
          IconButton(
            tooltip: 'Upload barcode image',
            onPressed: _busy ? null : _showUploadOptions,
            icon: const Icon(Icons.photo_library_outlined),
          ),
          IconButton(
            tooltip: 'Flashlight',
            onPressed: _controller.toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 300,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              _busy
                  ? 'Looking up product…'
                  : 'Fit the product barcode inside the frame',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          if (_busy) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
