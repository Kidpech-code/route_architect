import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:route_architect_example/main.dart';

void main() {
  testWidgets('Material pages and bottom navigation work',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RouteArchitectExampleApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
      tester
          .widgetList<Navigator>(find.byType(Navigator))
          .expand((navigator) => navigator.pages)
          .any((page) => page is MaterialPage),
      isTrue,
    );

    await tester.tap(find.text('Login as Member'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    expect(find.text('Search Screen'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Detail (Deep Nest)'));
    await tester.pumpAndSettle();
    expect(find.text('Detail #42'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Detail #42'), findsNothing);
  });
}
