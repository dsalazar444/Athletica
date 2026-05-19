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

  /// Visibilidad de la rutina, indica si rutina es publica o no
  final bool isPublic;

  /// ID del usuario que creó la rutina (gestionado por el backend).
  final int? createdBy;

  /// Nombre del creador de la rutina.
  final String? creatorName;

  /// Indica si el usuario logueado sigue al creador de la rutina.
  final bool? isFollowing;

  /// IDs de los atletas que tienen asignada esta rutina (legacy).
  final List<int>? assignedAthletes;

  /// Conteo de atletas asignados (nuevo).
  final int assignedAthletesCount;

  /// Información básica de los atletas asignados (nombres y IDs).
  final List<Map<String, dynamic>> assignedAthletesInfo;

  /// Lista de ejercicios que componen esta rutina, incluyendo su orden.
  final List<RoutineExerciseModel> exercises;

  /// Número de likes en la rutina.
  final int likesCount;

  /// Indica si el usuario autenticado dio like a esta rutina.
  final bool userLiked;

  /// Número de comentarios de primer nivel en la rutina.
  final int commentsCount;

  RoutineModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.isPublic,
    this.createdBy,
    this.creatorName,
    this.isFollowing,
    this.assignedAthletes,
    this.assignedAthletesCount = 0,
    this.assignedAthletesInfo = const [],
    required this.exercises,
    this.likesCount = 0,
    this.userLiked = false,
    this.commentsCount = 0,
  });

  /// Crea una instancia de [RoutineModel] desde un mapa JSON proveniente del backend.
  factory RoutineModel.fromJson(Map<String, dynamic> json) => RoutineModel(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    category: json['category'],
    difficulty: json['difficulty'],
    isPublic: json['is_public'] ?? true,
    createdBy: json['created_by'],
    creatorName: json['creator_name'],
    isFollowing: json['creator_is_following'],
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
    likesCount: json['likes_count'] ?? 0,
    userLiked: json['user_liked'] ?? false,
    commentsCount: json['comments_count'] ?? 0,
  );

  /// Convierte el modelo a un mapa JSON para ser enviado al servidor.
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'difficulty': difficulty,
    'is_public': isPublic,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  /// Crea una copia de esta rutina con algunos campos sobrescritos.
  RoutineModel copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    bool? isPublic,
    int? createdBy,
    String? creatorName,
    bool? isFollowing,
    List<int>? assignedAthletes,
    int? assignedAthletesCount,
    List<Map<String, dynamic>>? assignedAthletesInfo,
    List<RoutineExerciseModel>? exercises,
    int? likesCount,
    bool? userLiked,
    int? commentsCount,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isPublic: isPublic ?? this.isPublic,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      isFollowing: isFollowing ?? this.isFollowing,
      assignedAthletes: assignedAthletes ?? this.assignedAthletes,
      assignedAthletesCount:
          assignedAthletesCount ?? this.assignedAthletesCount,
      assignedAthletesInfo: assignedAthletesInfo ?? this.assignedAthletesInfo,
      exercises: exercises ?? this.exercises,
      likesCount: likesCount ?? this.likesCount,
      userLiked: userLiked ?? this.userLiked,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
