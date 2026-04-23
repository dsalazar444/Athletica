import '../../models/routine/workout_set_ui_model.dart';
import '../../models/routine/exercise_model.dart';

class ActiveExerciseModel {
  final ExerciseModel exercise;
  final int restSeconds;
  final List<WorkoutSetUiModel> sets;

  const ActiveExerciseModel({
    required this.exercise,
    required this.restSeconds,
    required this.sets,
  });

  int get id => exercise.id;
  String get name => exercise.name;
  String get initials => _buildInitials(exercise.name);
}

String _buildInitials(String name) {
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .take(2)
      .join()
      .toUpperCase();
}
