import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sms_backup_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
