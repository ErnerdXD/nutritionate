import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/services/barcode_validator.dart';

void main() {
  test('accepts valid EAN-8 and EAN-13 codes', () {
    expect(BarcodeValidator.isValidGtin('96385074'), isTrue);
    expect(BarcodeValidator.isValidGtin('9556995204554'), isTrue);
  });

  test('rejects misread and malformed codes', () {
    expect(BarcodeValidator.isValidGtin('13884729'), isFalse);
    expect(BarcodeValidator.isValidGtin('ABC12345'), isFalse);
    expect(BarcodeValidator.isValidGtin('123'), isFalse);
  });
}
