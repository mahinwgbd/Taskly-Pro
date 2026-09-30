import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todolist/main.dart';

void main() {
  testWidgets('Taskly opens the onboarding screen', (tester) async {
    await tester.pumpWidget(const TodoApp());
    await tester.pumpAndSettle();
    expect(find.text('Make room for\nwhat matters.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
