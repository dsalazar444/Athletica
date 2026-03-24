import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _athleteIdKey = 'athlete_id';
  static const _nameKey = 'user_name';

  static Future<void> saveTokens({
    required String access,
    required String refresh,
    int? athleteId,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    if (athleteId != null) {
      await prefs.setInt(_athleteIdKey, athleteId);
    }
    if (name != null) {
      await prefs.setString(_nameKey, name);
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

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_athleteIdKey);
    await prefs.remove(_nameKey);
  }
}