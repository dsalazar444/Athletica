import 'workout_history_item_model.dart';

/// Modelo para representar la respuesta paginada del historial de entrenamientos.
class PaginatedWorkoutHistoryModel {
  final int count;
  final String? next;
  final String? previous;
  final List<WorkoutHistoryItemModel> results;

  PaginatedWorkoutHistoryModel({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedWorkoutHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaginatedWorkoutHistoryModel(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List? ?? [])
          .map((e) => WorkoutHistoryItemModel.fromJson(e))
          .toList(),
    );
  }
}
