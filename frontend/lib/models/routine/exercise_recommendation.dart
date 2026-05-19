class ExerciseRecommendation {
  final String exerciseName;
  final String reason;
  final String imageUrl;
  final int? exerciseId;
  final int sets;
  final String reps;
  final int rest;
  final String instructions;
  final String muscle;
  final String youtubeId;

  ExerciseRecommendation({
    required this.exerciseName,
    required this.reason,
    required this.imageUrl,
    this.exerciseId,
    this.sets = 3,
    this.reps = "12",
    this.rest = 60,
    this.instructions = "",
    this.muscle = "General",
    this.youtubeId = "",
  });

  factory ExerciseRecommendation.fromJson(Map<String, dynamic> json) {
    return ExerciseRecommendation(
      exerciseName: json['exercise_name'] ?? '',
      reason: json['reason'] ?? '',
      imageUrl: json['image_url'] ?? '',
      exerciseId: json['exercise_id'],
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? '12',
      rest: json['rest'] ?? 60,
      instructions: json['instructions'] ?? '',
      muscle: json['muscle'] ?? 'General',
      youtubeId: json['youtube_id'] ?? '',
    );
  }
}

class RecommendationResponse {
  final List<ExerciseRecommendation> recommendations;
  final DateTime generatedAt;

  RecommendationResponse({
    required this.recommendations,
    required this.generatedAt,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    return RecommendationResponse(
      recommendations: (json['recommendations'] as List)
          .map((item) => ExerciseRecommendation.fromJson(item))
          .toList(),
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }
}
