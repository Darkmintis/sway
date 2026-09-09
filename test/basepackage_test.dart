import 'package:basepackage/basepackage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package loads', () {
    expect(const BasePackage(), isA<BasePackage>());
  });
}
