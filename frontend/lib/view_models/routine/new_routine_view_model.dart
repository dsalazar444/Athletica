import '../../repositories/routine/routine_repository.dart';
import '../../models/routine/selected_exercise.dart';
import '../../models/routine/routine_model.dart';
import '../../models/routine/routine__exercise_model.dart';

class RoutineViewModel {
  final RoutineRepository routineRepository;

  RoutineViewModel({required this.routineRepository});

  Future<void> saveRoutine({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required List<SelectedExercise> selectedExercises,
  }) async {
    // Transforma SelectedExercise a RoutineExerciseModel
    final exercises = selectedExercises
        .map((e) => RoutineExerciseModel(order: e.order, exercise: e.exercise))
        .toList();

    // creamos objeto Routine
    final routine = RoutineModel(
      title: title,
      description: description,
      category: category,
      difficulty: difficulty,
      exercises: exercises, // transformados a RoutineExercises (con order)
    );

    await routineRepository.createRoutine(routine); // creamos rutina -> verificamos que ejercicios existan primero
  }
}