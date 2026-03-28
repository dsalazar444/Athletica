import './exercise_model.dart';

/// Clase auxiliar que representa un ejercicio seleccionado temporalmente en la UI de "Nueva Rutina".
/// Incluye el objeto del ejercicio y la posición (orden) que ocupará en la lista antes de guardarse.
class SelectedExercise {
  /// El modelo completo del ejercicio seleccionado.
  final ExerciseModel exercise;

  /// El orden correlativo asignado por el usuario (ej. 1, 2, 3).
  final int order;

  const SelectedExercise({required this.exercise, required this.order});
}
