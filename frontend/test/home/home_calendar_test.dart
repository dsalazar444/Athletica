import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/api_client.dart';
import 'package:frontend/theme/app_colors.dart';
import 'package:frontend/views/home/home_screen.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.responses);

  final Map<String, dynamic> responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = responses[options.path];
    if (response == null) {
      throw StateError('Unexpected request: ${options.path}');
    }

    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_name': 'Carlos',
    });
  });

  tearDown(() {
    ApiClient.dio.httpClientAdapter.close(force: true);
    ApiClient.dio.httpClientAdapter = IOHttpClientAdapter();
  });

  testWidgets('muestra actividad de solo ejercicio en el calendario', (
    WidgetTester tester,
  ) async {
    await _pumpHomeWithCalendarData(
      tester,
      workoutDays: [DateTime.now()],
      mealDays: const [],
    );

    await _expectCalendarDayColor(
      tester,
      DateTime.now(),
      const Color(0xFF3B82F6),
    );
  });

  testWidgets('muestra actividad de solo comida en el calendario', (
    WidgetTester tester,
  ) async {
    await _pumpHomeWithCalendarData(
      tester,
      workoutDays: const [],
      mealDays: [DateTime.now()],
    );

    await _expectCalendarDayColor(
      tester,
      DateTime.now(),
      AppColors.success,
    );
  });

  testWidgets('muestra actividad combinada en el calendario', (
    WidgetTester tester,
  ) async {
    final today = DateTime.now();

    await _pumpHomeWithCalendarData(
      tester,
      workoutDays: [today],
      mealDays: [today],
    );

    await _expectCalendarDayColor(
      tester,
      today,
      AppColors.intensityNeon,
    );
  });
}

Future<void> _pumpHomeWithCalendarData(
  WidgetTester tester, {
  required List<DateTime> workoutDays,
  required List<DateTime> mealDays,
}) async {
  final adapter = _FakeHttpClientAdapter({
    'sessions/history/': {
      'count': workoutDays.length,
      'next': null,
      'previous': null,
      'results': workoutDays
          .map(
            (day) => {
              'id': day.millisecondsSinceEpoch,
              'routine': 1,
              'routine_title': 'Rutina',
              'date': day.toIso8601String(),
            },
          )
          .toList(),
    },
    'nutrition/meals/': mealDays
        .map(
          (day) => {
            'id': day.millisecondsSinceEpoch,
            'athlete': 1,
            'meal_type': 'lunch',
            'food_name': 'Pollo',
            'portion_grams': 100,
            'calories': 120,
            'protein_g': 20,
            'carbs_g': 0,
            'fat_g': 3,
            'date': _formatDate(day),
            'created_at': null,
          },
        )
        .toList(),
  });

  ApiClient.dio.httpClientAdapter = adapter;

  await tester.pumpWidget(
    const MaterialApp(
      home: HomeScreen(athleteId: 1),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _expectCalendarDayColor(
  WidgetTester tester,
  DateTime date,
  Color expectedColor,
) async {
  final dayLabel = date.day.toString();
  final dayTextFinder = find.descendant(
    of: find.byType(GridView),
    matching: find.text(dayLabel),
  );

  expect(dayTextFinder, findsOneWidget);

  final cellFinder = find.ancestor(
    of: dayTextFinder,
    matching: find.byWidgetPredicate((widget) {
      return widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == expectedColor;
    }),
  ).first;

  expect(cellFinder, findsOneWidget);

  final cell = tester.widget<Container>(cellFinder);
  final decoration = cell.decoration as BoxDecoration;
  expect(decoration.color, expectedColor);
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}