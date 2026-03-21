import '../../models/routine/exercise_model.dart';
import '../../repositories/routine/exercise_repository.dart';

class ExerciseViewModel {
  final ExerciseRepository repository;

  List<ExerciseModel> exercises = [];

  ExerciseViewModel(this.repository);

  Future<void> loadExercises() async {
    exercises = await repository.getExercises();
    final images = await repository.getExerciseImages(exercises.map((e) => e.id).toList());
    exercises = repository.combineExercisesWithImages(exercises, images);
  }

  // Devuelve la lista de ejercicios filtrada según el query (barra)
  List<ExerciseModel> filteredExercises(String query) {
    if (query.isEmpty) return exercises;
    return exercises
        .where((exercise) => exercise.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}