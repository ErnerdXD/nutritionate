import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/screens/home_screen.dart';

void main() {
  testWidgets('home screen invites the user to scan', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text("Know what's inside"), findsOneWidget);
    expect(find.text('Scan a barcode'), findsOneWidget);
  });
}
