// Integration test for the route_architect example app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:route_architect_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and shows login or home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RouteArchitectExampleApp());
    await tester.pumpAndSettle();

    // The app should render something – either the login page or home page.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
