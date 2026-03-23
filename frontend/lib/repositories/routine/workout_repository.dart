import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/routine/workout_session_model.dart';
import '../../models/routine/set_log_model.dart';
import '../../models/routine/paginated_workout_history_model.dart';

/// Repositorio encargado de gestionar la persistencia de las sesiones de entrenamiento.
/// Maneja la creación de sesiones, el guardado de series (sets) y la obtención del historial.
class WorkoutRepository {
  final String baseUrl;

  WorkoutRepository({required this.baseUrl});

  /// Inicia una nueva sesión de entrenamiento para una rutina específica.
  /// Si se proporciona una [date], la sesión se registrará en esa fecha.
  /// Retorna un [WorkoutSessionModel] con el ID de la sesión creada/reutilizada.
  Future<WorkoutSessionModel> startSession(int routineId, {DateTime? date}) async {
    final Map<String, dynamic> body = {'routine': routineId};
    if (date != null) {
      body['date'] = date.toIso8601String();
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/sessions/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return WorkoutSessionModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al iniciar o recuperar la sesión de entrenamiento.');
    }
  }

  /// Registra una nueva serie (set) en el backend.
  Future<SetLogModel> saveSet(SetLogModel setLog) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sets/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(setLog.toJson()),
    );

    if (response.statusCode == 201) {
      return SetLogModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al guardar la serie de ejercicio.');
    }
  }

  /// Actualiza una serie (set) existente en el backend.
  Future<SetLogModel> updateSet(SetLogModel setLog) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sets/${setLog.id}/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(setLog.toJson()),
    );

    if (response.statusCode == 200) {
      return SetLogModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar la serie de ejercicio.');
    }
  }

  /// Elimina una serie (set) permanentemente según su [setId].
  Future<void> deleteSet(int setId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sets/$setId/'),
    );

    if (response.statusCode != 204) {
      throw Exception('Error al eliminar la serie de la base de datos.');
    }
  }

  /// Obtiene las series del último entrenamiento realizado para un ejercicio específico.
  /// Útil para pre-llenar sugerencias de peso y repeticiones.
  Future<List<SetLogModel>> fetchLastExerciseLogs(int exerciseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/exercises/$exerciseId/last/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => SetLogModel.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      // Retorna lista vacía si no hay entrenamientos previos registrados.
      return [];
    } else {
      throw Exception('Error al obtener el último registro para las sugerencias.');
    }
  }

  /// Obtiene el historial completo de entrenamientos realizados para un ejercicio específico.
  /// Retorna una lista de mapas con las fechas y las series realizadas.
  Future<List<Map<String, dynamic>>> fetchExerciseHistory(int exerciseId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/exercises/$exerciseId/history/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Error al obtener el historial de este ejercicio.');
    }
  }

  /// Obtiene el historial paginado de sesiones en un rango de fechas.
  Future<PaginatedWorkoutHistoryModel> fetchWorkoutHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int page = 1,
    int pageSize = 10,
  }) async {
    final start = _formatDate(startDate);
    final end = _formatDate(endDate);

    final uri = Uri.parse('$baseUrl/sessions/history/').replace(
      queryParameters: {
        'start_date': start,
        'end_date': end,
        'page': '$page',
        'page_size': '$pageSize',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return PaginatedWorkoutHistoryModel.fromJson(json.decode(response.body));
    }

    throw Exception('Error al obtener el historial de entrenamientos.');
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
