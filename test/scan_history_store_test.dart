import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/services/scan_history_store.dart';

void main() {
  test('scan history storage is isolated by Firebase user ID', () {
    expect(
      ScanHistoryStore.keyForUser('new-user'),
      isNot(ScanHistoryStore.keyForUser('existing-user')),
    );
  });
}
