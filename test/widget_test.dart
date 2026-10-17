import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base/main.dart';

void main() {
  testWidgets('builds the application shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
