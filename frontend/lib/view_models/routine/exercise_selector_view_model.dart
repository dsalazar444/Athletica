import '../../models/routine/exercise_model.dart';
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
    final images = await repository.getExerciseImages(exercises.map((e) => e.id).toList());
    
    // Vinculamos las imágenes a cada modelo de ejercicio para su visualización.
    exercises = repository.combineExercisesWithImages(exercises, images);
  }

  /// Filtra la lista local de ejercicios basándose en una cadena de búsqueda [query].
  /// Realiza una comparación insensible a mayúsculas/minúsculas sobre el nombre del ejercicio.
  List<ExerciseModel> filteredExercises(String query) {
    if (query.isEmpty) return exercises;
    return exercises
        .where((exercise) => exercise.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}