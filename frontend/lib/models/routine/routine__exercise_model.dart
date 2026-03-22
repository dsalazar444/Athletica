import '../../models/routine/exercise_model.dart';

// relacion entre una rutina y sus ejercicios, para modelo en backend routineExercise
class RoutineExerciseModel {
  final int order;
  final ExerciseModel exercise;

  RoutineExerciseModel({
    required this.order,
    required this.exercise,
  });

  factory RoutineExerciseModel.fromJson(Map<String, dynamic> json) => RoutineExerciseModel(
        order: json['order'],
        exercise: json['exercise'] != null
            ? ExerciseModel.fromJson(json['exercise'])
            : ExerciseModel(id: 0, name: '', description: '', muscles: []), // maneja el caso null 
      );

  Map<String, dynamic> toJson() => {
        'external_id': exercise.id,
        'order': order,
      };
}