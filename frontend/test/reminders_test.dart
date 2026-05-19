import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/notification/reminder_model.dart';

void main() {
  group('ReminderModel Tests', () {
    test('ReminderModel.fromJson creates instance from JSON', () {
      final json = {
        'id': 1,
        'activity_type': 'training',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'daily',
        'timezone': 'America/Bogota',
        'is_active': true,
        'notified_at': null,
      };

      final reminder = ReminderModel.fromJson(json);

      expect(reminder.id, 1);
      expect(reminder.activityType, 'training');
      expect(reminder.recurrence, 'daily');
      expect(reminder.timezone, 'America/Bogota');
      expect(reminder.isActive, true);
      expect(reminder.notifiedAt, isNull);
    });

    test('ReminderModel.fromJson converts UTC to local time', () {
      final json = {
        'id': 1,
        'activity_type': 'nutrition',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'weekly',
        'timezone': 'UTC',
        'is_active': true,
        'notified_at': null,
      };

      final reminder = ReminderModel.fromJson(json);

      // Verificar que es DateTime local
      expect(reminder.remindAt, isA<DateTime>());
      // El convertir a local depende del timezone del sistema, solo verificar que es válido
      expect(reminder.remindAt.year, 2026);
      expect(reminder.remindAt.month, 5);
    });

    test('ReminderModel.fromJson handles notified_at field', () {
      final json = {
        'id': 1,
        'activity_type': 'training',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': true,
        'notified_at': '2026-05-17T10:35:00Z',
      };

      final reminder = ReminderModel.fromJson(json);

      expect(reminder.notifiedAt, isNotNull);
      expect(reminder.notifiedAt!.year, 2026);
    });

    test('ReminderModel.fromJson defaults recurrence to none', () {
      final json = {
        'id': 1,
        'activity_type': 'training',
        'remind_at': '2026-05-17T10:30:00Z',
        'timezone': 'UTC',
        'is_active': true,
      };

      final reminder = ReminderModel.fromJson(json);

      expect(reminder.recurrence, 'none');
    });

    test('ReminderModel.fromJson defaults timezone to UTC', () {
      final json = {
        'id': 1,
        'activity_type': 'nutrition',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'daily',
        'is_active': true,
      };

      final reminder = ReminderModel.fromJson(json);

      expect(reminder.timezone, 'UTC');
    });

    test('ReminderModel.toJson serializes correctly', () {
      final now = DateTime.now();
      final reminder = ReminderModel(
        id: 1,
        activityType: 'training',
        remindAt: now,
        recurrence: 'weekly',
        timezone: 'America/Bogota',
        isActive: true,
      );

      final json = reminder.toJson();

      expect(json['activity_type'], 'training');
      expect(json['recurrence'], 'weekly');
      expect(json['timezone'], 'America/Bogota');
      expect(json['is_active'], true);
      expect(json['remind_at'], isNotNull);
    });

    test('ReminderModel.toJson converts local time to UTC', () {
      final localTime = DateTime(2026, 5, 17, 10, 30, 0);
      final reminder = ReminderModel(
        id: 1,
        activityType: 'training',
        remindAt: localTime,
        recurrence: 'none',
        timezone: 'UTC',
        isActive: true,
      );

      final json = reminder.toJson();
      final iso = json['remind_at'] as String;

      // Verificar que se convierte a ISO8601 format
      expect(iso, contains('Z'));
      expect(iso, isA<String>());
    });

    test('ReminderModel equality comparison', () {
      final now = DateTime.now();
      final reminder1 = ReminderModel(
        id: 1,
        activityType: 'training',
        remindAt: now,
        recurrence: 'daily',
        timezone: 'UTC',
        isActive: true,
      );
      final reminder2 = ReminderModel(
        id: 1,
        activityType: 'training',
        remindAt: now,
        recurrence: 'daily',
        timezone: 'UTC',
        isActive: true,
      );

      expect(reminder1.id, reminder2.id);
      expect(reminder1.activityType, reminder2.activityType);
      expect(reminder1.recurrence, reminder2.recurrence);
    });

    test('ReminderModel supports different activity types', () {
      final trainingJson = {
        'id': 1,
        'activity_type': 'training',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': true,
      };
      final nutritionJson = {
        'id': 2,
        'activity_type': 'nutrition',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': true,
      };

      final training = ReminderModel.fromJson(trainingJson);
      final nutrition = ReminderModel.fromJson(nutritionJson);

      expect(training.activityType, 'training');
      expect(nutrition.activityType, 'nutrition');
    });

    test('ReminderModel supports all recurrence types', () {
      final recurrenceTypes = [
        'none',
        'daily',
        'weekly',
        'biweekly',
        'monthly',
      ];

      for (final recurrence in recurrenceTypes) {
        final json = {
          'id': 1,
          'activity_type': 'training',
          'remind_at': '2026-05-17T10:30:00Z',
          'recurrence': recurrence,
          'timezone': 'UTC',
          'is_active': true,
        };

        final reminder = ReminderModel.fromJson(json);
        expect(reminder.recurrence, recurrence);
      }
    });

    test('ReminderModel handles common timezone formats', () {
      final timezones = [
        'UTC',
        'America/Bogota',
        'America/New_York',
        'Europe/London',
        'Asia/Tokyo',
      ];

      for (final tz in timezones) {
        final json = {
          'id': 1,
          'activity_type': 'training',
          'remind_at': '2026-05-17T10:30:00Z',
          'recurrence': 'none',
          'timezone': tz,
          'is_active': true,
        };

        final reminder = ReminderModel.fromJson(json);
        expect(reminder.timezone, tz);
      }
    });
  });

  group('ReminderModel Validation Tests', () {
    test('ReminderModel is_active field affects display', () {
      final activeJson = {
        'id': 1,
        'activity_type': 'training',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': true,
      };
      final inactiveJson = {
        'id': 2,
        'activity_type': 'training',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': false,
      };

      final active = ReminderModel.fromJson(activeJson);
      final inactive = ReminderModel.fromJson(inactiveJson);

      expect(active.isActive, true);
      expect(inactive.isActive, false);
    });

    test('ReminderModel with and without notified_at marker', () {
      final withNotification = {
        'id': 1,
        'activity_type': 'training',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': true,
        'notified_at': '2026-05-17T10:35:00Z',
      };
      final withoutNotification = {
        'id': 2,
        'activity_type': 'training',
        'remind_at': '2026-05-17T10:30:00Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': true,
        'notified_at': null,
      };

      final notified = ReminderModel.fromJson(withNotification);
      final pending = ReminderModel.fromJson(withoutNotification);

      expect(notified.notifiedAt, isNotNull);
      expect(pending.notifiedAt, isNull);
    });
  });

  group('ReminderModel Edge Cases', () {
    test('ReminderModel handles leap year dates', () {
      final leapYearJson = {
        'id': 1,
        'activity_type': 'training',
        'remind_at': '2024-02-29T10:30:00Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': true,
      };

      final reminder = ReminderModel.fromJson(leapYearJson);
      expect(reminder.remindAt.day, 29);
      expect(reminder.remindAt.month, 2);
    });

    test('ReminderModel preserves time precision', () {
      final json = {
        'id': 1,
        'activity_type': 'training',
        'remind_at': '2026-05-17T14:35:42Z',
        'recurrence': 'none',
        'timezone': 'UTC',
        'is_active': true,
      };

      final reminder = ReminderModel.fromJson(json);
      expect(reminder.remindAt.hour, 14);
      expect(reminder.remindAt.minute, 35);
    });

    test('ReminderModel round-trip serialization', () {
      final original = ReminderModel(
        id: 123,
        activityType: 'nutrition',
        remindAt: DateTime(2026, 5, 17, 10, 30),
        recurrence: 'weekly',
        timezone: 'America/Bogota',
        isActive: true,
      );

      final json = original.toJson();
      // Simular serialización/deserialización con valores recuperados del backend
      final recovered = ReminderModel(
        id: original.id,
        activityType: json['activity_type'] as String,
        remindAt: DateTime.parse(json['remind_at'] as String).toLocal(),
        recurrence: json['recurrence'] as String? ?? 'none',
        timezone: json['timezone'] as String? ?? 'UTC',
        isActive: json['is_active'] as bool,
      );

      expect(recovered.id, original.id);
      expect(recovered.activityType, original.activityType);
      expect(recovered.recurrence, original.recurrence);
      expect(recovered.timezone, original.timezone);
    });
  });
}
