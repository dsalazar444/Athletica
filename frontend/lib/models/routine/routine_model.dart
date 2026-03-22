import '../../models/routine/routine__exercise_model.dart';

class RoutineModel {
  final int? id; // Es la primary key, la asigna el backend al crear la rutina
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int? createdBy; // id del usuario creador (opcional, lo asigna el backend en serializer)
  final List<int>? assignedAthletes; // ids de usuarios asignados (opcional, lo asigna el backend en serializer)
  final List<RoutineExerciseModel> exercises;

  RoutineModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.createdBy,
    this.assignedAthletes,
    required this.exercises,
  });

    factory RoutineModel.fromJson(Map<String, dynamic> json) => RoutineModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      category: json['category'],
      difficulty: json['difficulty'],
      createdBy: json['created_by'],
      assignedAthletes: (json['assigned_athletes'] != null)
        ? (json['assigned_athletes'] as List).map((e) => e as int).toList()
        : [],
      exercises: (json['exercises'] != null)
        ? (json['exercises'] as List).map((e) => RoutineExerciseModel.fromJson(e)).toList()
        : [],
    );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        // 'created_by': createdBy, // normalmente lo asigna el backend
        // 'assigned_athletes': assignedAthletes, // opcional
      };
}