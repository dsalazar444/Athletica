import '../../models/routine/routine__exercise_model.dart';

/// Modelo que representa una rutina de entrenamiento completa.
/// Incluye metadatos como título, descripción, categoría y dificultad,
/// además de la lista de ejercicios asociados.
class RoutineModel {
  /// Identificador único generado por el backend al persistir la rutina.
  final int? id;

  /// Título descriptivo de la rutina (ej. "Empuje/Tracción").
  final String title;

  /// Descripción detallada de los objetivos de la rutina.
  final String description;

  /// Categoría de la rutina (ej. "Fuerza", "Hipertrofia").
  final String category;

  /// Nivel de dificultad estimado (ej. "Principiante").
  final String difficulty;

  /// ID del usuario que creó la rutina (gestionado por el backend).
  final int? createdBy;

  /// Nombre del creador de la rutina.
  final String? creatorName;

  /// IDs de los atletas que tienen asignada esta rutina (legacy).
  final List<int>? assignedAthletes;

  /// Conteo de atletas asignados (nuevo).
  final int assignedAthletesCount;

  /// Información básica de los atletas asignados (nombres y IDs).
  final List<Map<String, dynamic>> assignedAthletesInfo;

  /// Lista de ejercicios que componen esta rutina, incluyendo su orden.
  final List<RoutineExerciseModel> exercises;

  RoutineModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.createdBy,
    this.creatorName,
    this.assignedAthletes,
    this.assignedAthletesCount = 0,
    this.assignedAthletesInfo = const [],
    required this.exercises,
  });

  /// Crea una instancia de [RoutineModel] desde un mapa JSON proveniente del backend.
  factory RoutineModel.fromJson(Map<String, dynamic> json) => RoutineModel(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    category: json['category'],
    difficulty: json['difficulty'],
    createdBy: json['created_by'],
    creatorName: json['creator_name'],
    assignedAthletes: (json['assigned_athletes'] != null)
        ? (json['assigned_athletes'] as List).map((e) => e as int).toList()
        : [],
    assignedAthletesCount: json['assigned_athletes_count'] ?? 0,
    assignedAthletesInfo: (json['assigned_athletes_info'] != null)
        ? List<Map<String, dynamic>>.from(json['assigned_athletes_info'])
        : [],
    exercises: (json['exercises'] != null)
        ? (json['exercises'] as List)
              .map((e) => RoutineExerciseModel.fromJson(e))
              .toList()
        : [],
  );

  /// Convierte el modelo a un mapa JSON para ser enviado al servidor.
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'difficulty': difficulty,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}
