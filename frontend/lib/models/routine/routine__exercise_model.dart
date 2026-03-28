import '../../models/routine/exercise_model.dart';

/// Modelo que representa la relación entre una rutina y un ejercicio específico.
/// Este modelo refleja el objeto `RoutineExercise` persistido en el backend.
class RoutineExerciseModel {
  /// Posición del ejercicio dentro de la secuencia de la rutina.
  final int order;

  /// Detalles completos del ejercicio asociado.
  final ExerciseModel exercise;

  RoutineExerciseModel({required this.order, required this.exercise});

  /// Construye una instancia de [RoutineExerciseModel] desde un JSON del servidor.
  factory RoutineExerciseModel.fromJson(Map<String, dynamic> json) =>
      RoutineExerciseModel(
        order: json['order'],
        exercise: json['exercise'] != null
            ? ExerciseModel.fromJson(json['exercise'])
            : ExerciseModel(
                id: 0,
                name: 'Desconocido',
                description: '',
                muscles: [],
              ),
      );

  /// Convierte el modelo a un formato compatible para enviar al backend.
  /// Se envía el `id` como `external_id` tal como lo espera el serializer de la rutina.
  Map<String, dynamic> toJson() => {'external_id': exercise.id, 'order': order};
}
