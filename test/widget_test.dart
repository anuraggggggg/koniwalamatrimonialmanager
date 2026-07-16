import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koniwalamatrimonial/main.dart';

void main() {
  testWidgets('App builds with configured MaterialApp', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
