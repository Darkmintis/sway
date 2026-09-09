import 'package:basepackage/basepackage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

/// Example app for the package template.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Example')),
        body: Center(child: Text('$BasePackage()')),
      ),
    );
  }
}
