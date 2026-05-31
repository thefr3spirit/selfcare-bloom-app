// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selfcare_together/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // This is a minimal smoke test to verify the app builds
    // Full tests should be in integration tests due to Hive initialization requirements

    // Build the app widget tree
    await tester.pumpWidget(const SelfCareTogetherApp());

    // Verify that the app title is set correctly
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'SelfCare Together');
  });
}
