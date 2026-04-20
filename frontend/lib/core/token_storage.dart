import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _athleteIdKey = 'athlete_id';
  static const _userIdKey = 'user_id';
  static const _nameKey = 'user_name';
  static const _roleKey = 'user_role';
  static const _lastRoutineKey = 'last_routine_id';

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
}
