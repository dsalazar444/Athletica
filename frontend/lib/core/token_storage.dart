import 'dart:convert';

import 'package:frontend/models/notification/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _athleteIdKey = 'athlete_id';
  static const _userIdKey = 'user_id';
  static const _nameKey = 'user_name';
  static const _roleKey = 'user_role';
  static const _lastRoutineKey = 'last_routine_id';
  static const _notificationsKey = 'saved_notifications';
  static const _shownReminderIdsKey = 'shown_reminder_ids';
  static const _lastFollowersCountKey = 'last_followers_count';

  static Future<void> saveTokens({
    required String access,
    required String refresh,
    int? athleteId,
    int? userId,
    String? name,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    if (athleteId != null) {
      await prefs.setInt(_athleteIdKey, athleteId);
    }
    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    }
    if (name != null) {
      await prefs.setString(_nameKey, name);
    }
    if (role != null) {
      await prefs.setString(_roleKey, role);
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<int?> getAthleteId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_athleteIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_athleteIdKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_lastRoutineKey);
    await prefs.remove(_notificationsKey);
    await prefs.remove(_shownReminderIdsKey);
    await prefs.remove(_lastFollowersCountKey);
  }

  static Future<void> saveLastRoutineId(int? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_lastRoutineKey);
    } else {
      await prefs.setInt(_lastRoutineKey, id);
    }
  }

  static Future<int?> getLastRoutineId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastRoutineKey);
  }

  static Future<void> saveNotifications(
    List<NotificationModel> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = notifications
        .map((notification) => notification.toJson())
        .toList();
    await prefs.setString(_notificationsKey, jsonEncode(payload));
  }

  static Future<List<NotificationModel>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  static Future<void> addShownReminderId(int reminderId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shownReminderIdsKey);
    final Set<String> ids = <String>{};
    if (raw != null && raw.isNotEmpty) {
      ids.addAll((jsonDecode(raw) as List<dynamic>).cast<String>());
    }
    ids.add(reminderId.toString());
    await prefs.setString(_shownReminderIdsKey, jsonEncode(ids.toList()));
  }

  static Future<Set<int>> getShownReminderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shownReminderIdsKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = (jsonDecode(raw) as List<dynamic>).cast<String>();
    return decoded.map((id) => int.parse(id)).toSet();
  }

  static Future<void> clearShownReminderIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shownReminderIdsKey);
  }

  static Future<void> saveLastFollowersCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastFollowersCountKey, count);
  }

  static Future<int?> getLastFollowersCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastFollowersCountKey);
  }
}
