// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('WorkoutApp renders login screen by default', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences para evitar errores de persistencia en test
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const WorkoutApp());
    await tester.pumpAndSettle();

    // Verifica que se renderiza el texto de bienvenida o el titulo de login
    expect(find.text('BIENVENIDO'), findsOneWidget);
    expect(find.text('Usuario o Email'), findsOneWidget);
  });
}
