import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:route_architect_example/main.dart';

void main() {
  testWidgets('App renders a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const RouteArchitectExampleApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
