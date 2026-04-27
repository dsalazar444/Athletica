import '../../core/api_client.dart';
import '../../models/profile/profile_settings_model.dart';

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
}
