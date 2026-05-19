import 'package:dio/dio.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/notification/reminder_model.dart';

class ReminderService {
  Future<List<ReminderModel>> getReminders() async {
    final response = await ApiClient.dio.get('reminders/');
    final data = response.data as List<dynamic>;
    return data.map((json) => ReminderModel.fromJson(json)).toList();
  }

  Future<ReminderModel> createReminder({
    required String activityType,
    required DateTime remindAt,
    String? recurrence,
    String? timezone,
    bool isActive = true,
  }) async {
    final response = await ApiClient.dio.post(
      'reminders/',
      data: {
        'activity_type': activityType,
        'remind_at': remindAt.toUtc().toIso8601String(),
        'recurrence': recurrence ?? 'none',
        'timezone': timezone ?? 'UTC',
        'is_active': isActive,
      },
    );
    return ReminderModel.fromJson(response.data);
  }

  Future<ReminderModel> updateReminder(
    int id, {
    String? activityType,
    DateTime? remindAt,
    String? recurrence,
    String? timezone,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};
    if (activityType != null) payload['activity_type'] = activityType;
    if (remindAt != null) {
      payload['remind_at'] = remindAt.toUtc().toIso8601String();
    }
    if (recurrence != null) payload['recurrence'] = recurrence;
    if (timezone != null) payload['timezone'] = timezone;
    if (isActive != null) payload['is_active'] = isActive;

    final response = await ApiClient.dio.put('reminders/$id/', data: payload);
    return ReminderModel.fromJson(response.data);
  }

  Future<void> deleteReminder(int id) async {
    await ApiClient.dio.delete('reminders/$id/');
  }

  Future<List<ReminderModel>> getDueReminders() async {
    try {
      final response = await ApiClient.dio.get('reminders/due/');
      final data = response.data as List<dynamic>;
      // Debugging: print to console the raw due reminders
      try {
        // ignore: avoid_print
        print('ReminderService.getDueReminders -> count=${data.length}');
        for (final item in data) {
          // ignore: avoid_print
          print('  due: $item');
        }
      } catch (_) {}
      return data.map((json) => ReminderModel.fromJson(json)).toList();
    } on DioException catch (e) {
      // If we get a 401 it may be mid-refresh; wait a moment and retry once.
      if (e.response?.statusCode == 401) {
        // ignore: avoid_print
        print('ReminderService: received 401, waiting and retrying once');
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          final retry = await ApiClient.dio.get('reminders/due/');
          final data = retry.data as List<dynamic>;
          return data.map((json) => ReminderModel.fromJson(json)).toList();
        } catch (_) {
          // swallow and rethrow original to let caller handle
        }
      }
      rethrow;
    }
  }
}
