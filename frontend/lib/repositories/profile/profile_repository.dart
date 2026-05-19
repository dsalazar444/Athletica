import '../../core/api_client.dart';
import '../../models/profile/profile_settings_model.dart';
import '../../models/profile/comparative_stats_model.dart';

class ProfileRepository {
  Future<ProfileSettingsModel> getProfileSettings() async {
    final response = await ApiClient.dio.get('users/profile/settings/');
    return ProfileSettingsModel.fromJson(response.data);
  }

  Future<ProfileSettingsModel> updateProfileSettings(
    ProfileSettingsModel settings,
  ) async {
    final response = await ApiClient.dio.patch(
      'users/profile/settings/',
      data: settings.toUpdateJson(),
    );
    return ProfileSettingsModel.fromJson(response.data);
  }

  Future<ComparativeStatsModel> getComparativeStats({
    String period = 'monthly',
  }) async {
    final response = await ApiClient.dio.get(
      'dashboard/athlete/comparative-stats/',
      queryParameters: {'period': period},
    );
    return ComparativeStatsModel.fromJson(response.data);
  }
}
