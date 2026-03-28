import '../../models/routine/exercise_model.dart';
import '../../models/routine/routine_enums.dart';
import '../../repositories/routine/exercise_repository.dart';

/// ViewModel que gestiona la lógica de selección y filtrado de ejercicios para el catálogo.
/// Actúa como intermediario entre la vista del selector y el repositorio de ejercicios.
class ExerciseViewModel {
  final ExerciseRepository repository;

  /// Lista completa de ejercicios cargados desde el servidor.
  List<ExerciseModel> exercises = [];

  ExerciseViewModel(this.repository);

  /// Carga la lista inicial de ejercicios coordinando la obtención de datos e imágenes.
  Future<void> loadExercises() async {
    // Obtenemos los datos básicos del catálogo.
    exercises = await repository.getExercises();

    // Recuperamos las imágenes correspondientes a los ejercicios cargados.
    final images = await repository.getExerciseImages(
      exercises.map((e) => e.id).toList(),
    );

    // Vinculamos las imágenes a cada modelo de ejercicio para su visualización.
    exercises = repository.combineExercisesWithImages(exercises, images);
  }

  /// Filtra la lista local de ejercicios basándose en texto y categoría muscular.
  List<ExerciseModel> filteredExercises(String query, String categoryName) {
    return exercises.where((exercise) {
      // 1. Filtro por texto (nombre)
      final matchesQuery =
          query.isEmpty ||
          exercise.name.toLowerCase().contains(query.toLowerCase());

      // 2. Filtro por categoría (músculo)
      bool matchesCategory = true;
      if (categoryName != 'Todos') {
        final categoryEnum = _stringToMuscleGroup(categoryName);
        matchesCategory = exercise.muscleCategory == categoryEnum;
      }

      return matchesQuery && matchesCategory;
    }).toList();
  }

  /// Helper privado para convertir el nombre de la UI al Enum correspondiente.
  MuscleGroup? _stringToMuscleGroup(String name) {
    for (var group in MuscleGroup.values) {
      if (muscleGroupToString(group) == name) return group;
    }
    return null;
  }
}
