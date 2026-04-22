/// Modelo que representa el registro de una serie (set) individual de un ejercicio.
/// Contiene la información de repeticiones y peso para una sesión específica.
class LogSetModel {
  /// ID único del registro asignado por la base de datos.
  final int? id;

  /// ID de la sesión de entrenamiento a la que pertenece esta serie.
  final int? sessionId;

  /// ID del ejercicio que se está realizando.
  final int exerciseId;

  /// Número correlativo de la serie dentro del ejercicio (ej. Serie 1, Serie 2).
  final int setNumber;

  /// Cantidad de repeticiones logradas.
  final int reps;

  /// Peso utilizado en la serie (en kilogramos o libras según configuración).
  final double weight;
  
  LogSetModel({
    this.id,
    this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  /// Crea un [WorkoutSetModel] a partir de un mapa JSON del servidor.
  factory LogSetModel.fromJson(Map<String, dynamic> json) {
    return LogSetModel(
      id: json['id'],
      sessionId: json['session'],
      exerciseId: json['exercise'],
      setNumber: json['set_number'],
      reps: json['reps'],
      weight: double.parse(json['weight'].toString()),
    );
  }

  /// Convierte el objeto a JSON para ser enviado al backend.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (sessionId != null) 'session': sessionId,
      'exercise': exerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight': weight,
    };
  }

  /// Crea una copia del modelo con algunos campos modificados, manteniendo la inmutabilidad.
  LogSetModel copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? setNumber,
    int? reps,
    double? weight,
  }) {
    return LogSetModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
    );
  }
}
