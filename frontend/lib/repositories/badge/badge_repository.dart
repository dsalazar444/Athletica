import '../../core/api_client.dart';
import '../../models/badge/badge_model.dart';

class BadgeRepository {
  final String baseUrl;

  BadgeRepository({required this.baseUrl});

  Future<List<BadgeDefinition>> fetchAvailableBadges() async {
    final response = await ApiClient.dio.get('badges/');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => BadgeDefinition.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BadgeSummaryResponse> fetchUserBadgeSummary() async {
    final response = await ApiClient.dio.get('me/badges/');
    return BadgeSummaryResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
