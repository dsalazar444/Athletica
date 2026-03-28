import '../../repositories/routine/routine_repository.dart';
import '../../models/routine/selected_exercise.dart';
import '../../models/routine/routine_model.dart';
import '../../models/routine/routine__exercise_model.dart';

/// ViewModel responsable de la lógica para la creación de nuevas rutinas.
/// Se encarga de transformar los ejercicios seleccionados en la interfaz
/// al formato de persistencia requerido por el backend.
class RoutineViewModel {
  final RoutineRepository routineRepository;

  RoutineViewModel({required this.routineRepository});

  /// Crea y guarda una nueva rutina en el servidor.
  /// [selectedExercises] es la lista temporal de ejercicios elegidos por el usuario.
  Future<void> saveRoutine({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required List<SelectedExercise> selectedExercises,
  }) async {
    // Transformamos los SelectedExercise (que son temporales de la UI)
    // a RoutineExerciseModel (que incluyen el orden y el objeto de ejercicio).
    final exercises = selectedExercises
        .map((e) => RoutineExerciseModel(order: e.order, exercise: e.exercise))
        .toList();

    // Construimos el modelo completo de la rutina.
    final routine = RoutineModel(
      title: title,
      description: description,
      category: category,
      difficulty: difficulty,
      exercises: exercises,
    );

    // Persistimos la rutina a través de la capa de repositorio.
    // El repositorio se encargará de asegurar que los ejercicios existan en la BD local.
    await routineRepository.createRoutine(routine);
  }
}
