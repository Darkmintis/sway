import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sway_example/main.dart';

void main() {
  testWidgets('App builds and shows Sway brand', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('Sway'), findsWidgets);
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
  });
}
