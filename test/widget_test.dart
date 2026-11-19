import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Flutter test harness renders a basic MaterialApp', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Asset Flow')));
    expect(find.text('Asset Flow'), findsOneWidget);
  });
}
