import '../../models/routine/active_exercise_model.dart';
import '../../models/routine/routine__exercise_model.dart';
import '../../models/routine/set_log_model.dart';
import '../../models/routine/workout_set_ui_model.dart';
  
class ActiveWorkoutViewModel {
  static const int defaultSetCount = 3;
  static const int defaultRestSeconds = 90;
  static const int defaultReps = 0;
  static const double defaultWeight = 0;

  // Usamos valores predeterminados de setcount (porque actualmente no se guarda en bd, mejora para siguiente sprint -> pedir dato al crear rutina) 
  // y de defaultReps y defaultWeight para en siguiente sprint que estos se tomen desde backend y se muestre el ultimo valor de sus registros.
  List<ActiveExerciseModel> toActiveExercises(
    List<RoutineExerciseModel> routineExercises, {
    int defaultSetCount = ActiveWorkoutViewModel.defaultSetCount,
    int defaultRestSeconds = ActiveWorkoutViewModel.defaultRestSeconds,
    int defaultReps = ActiveWorkoutViewModel.defaultReps,
    double defaultWeight = ActiveWorkoutViewModel.defaultWeight,
    }) {
      final ordered = [...routineExercises]
        ..sort((a, b) => a.order.compareTo(b.order));
    
      return ordered.map((re) {
        final sets = List.generate(
          defaultSetCount,
          (index) => WorkoutSetUiModel(
            base: LogSetModel(
              exerciseId: re.exercise.id,
              setNumber: index + 1,
              reps: defaultReps,
              weight: defaultWeight,
            ),
          ),
        );
    
        return ActiveExerciseModel(
          exercise: re.exercise,
          restSeconds: defaultRestSeconds,
          sets: sets,
        );
      }).toList();
    }
}