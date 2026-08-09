class BarcodeValidator {
  static bool isValidGtin(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) return false;
    if (![8, 12, 13, 14].contains(value.length)) return false;

    var sum = 0;
    for (var index = value.length - 1; index >= 0; index--) {
      final digit = int.parse(value[index]);
      final positionFromRight = value.length - 1 - index;
      if (positionFromRight == 0) {
        sum += digit;
      } else {
        sum += digit * (positionFromRight.isOdd ? 3 : 1);
      }
    }
    return sum % 10 == 0;
  }
}
