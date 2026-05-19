import '../../core/api_client.dart';
import '../../models/routine/exercise_recommendation.dart';

class RecommendationRepository {
  final String baseUrl;

  RecommendationRepository({required this.baseUrl});

  Future<RecommendationResponse> fetchAIRecommendations() async {
    try {
      final response = await ApiClient.dio.post('routines/recommendations/');

      if (response.statusCode == 200) {
        return RecommendationResponse.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to load AI recommendations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching AI recommendations: $e');
    }
  }
}
