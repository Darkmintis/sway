import 'package:basepackage_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExampleApp builds', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Example'), findsOneWidget);
  });
}
