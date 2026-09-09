import 'package:flutter_test/flutter_test.dart';
import 'package:sway_example/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Sway Demo'), findsOneWidget);
  });
}
