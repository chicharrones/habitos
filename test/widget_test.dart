import 'package:flutter_test/flutter_test.dart';

import 'package:habitos/main.dart';

void main() {
  testWidgets('HabitosApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(HabitosApp());
    expect(find.byType(HabitosApp), findsOneWidget);
  });
}
