import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/services/byok_service.dart';

void main() {
  test('accepts standard and authorization Gemini key formats', () {
    expect(
      ByokService.isSupportedGeminiKey(
        'AIzaSyExampleKeyThatIsLongEnoughForValidation123',
      ),
      isTrue,
    );
    expect(
      ByokService.isSupportedGeminiKey(
        'AQ.ExampleAuthorizationKeyThatIsLongEnough_123',
      ),
      isTrue,
    );
  });

  test('rejects placeholders, whitespace, and unrelated values', () {
    expect(ByokService.isSupportedGeminiKey('123456'), isFalse);
    expect(ByokService.isSupportedGeminiKey('AQ.short'), isFalse);
    expect(
      ByokService.isSupportedGeminiKey(
        'AQ.Example Authorization Key With Spaces 123',
      ),
      isFalse,
    );
  });
}
