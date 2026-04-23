import 'set_log_model.dart';

/// Modelo que representa una sesión de entrenamiento completa.
/// Una sesión agrupa múltiples registros de series ([WorkoutSetModel]) para una rutina y fecha específicas.
class WorkoutSessionModel {
  /// Identificador único de la sesión generado por el backend.
  final int? id;

  /// ID de la rutina que se está ejecutando en esta sesión.
  final int routineId;

  /// Fecha y hora en la que se realizó (o se agendó) el entrenamiento.
  final DateTime? date;

  /// Lista de todas las series de ejercicios registradas durante esta sesión.
  final List<LogSetModel> setLogs;

  WorkoutSessionModel({
    this.id,
    required this.routineId,
    this.date,
    this.setLogs = const [],
  });

  /// Crea una instancia de [WorkoutSessionModel] desde un mapa JSON del servidor.
  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'],
      routineId: json['routine'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      setLogs: (json['set_logs'] as List? ?? [])
          .map((e) => LogSetModel.fromJson(e))
          .toList(),
    );
  }

  /// Convierte el modelo a JSON para su envío o persistencia.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'routine': routineId,
      if (date != null) 'date': date!.toIso8601String(),
    };
  }
}
