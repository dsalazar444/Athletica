import 'package:dio/dio.dart';
import '../../models/routine/workout_session_model.dart';
import '../../models/routine/set_log_model.dart';
import '../../models/routine/paginated_workout_history_model.dart';
import '../../core/api_client.dart';

/// Repositorio encargado de gestionar la persistencia de las sesiones de entrenamiento.
/// Maneja la creación de sesiones, el guardado de series (sets) y la obtención del historial.
class WorkoutRepository {
  final String baseUrl;
  final Dio _dio = ApiClient.dio;

  WorkoutRepository({required this.baseUrl});

  /// Inicia una nueva sesión de entrenamiento para una rutina específica.
  /// Si se proporciona una [date], la sesión se registrará en esa fecha.
  /// Retorna un [WorkoutSessionModel] con el ID de la sesión creada/reutilizada.
  Future<WorkoutSessionModel> startSession(
    int routineId, {
    DateTime? date,
  }) async {
    final Map<String, dynamic> body = {'routine': routineId};
    if (date != null) {
      body['date'] = date.toIso8601String();
    }

    try {
      final response = await _dio.post('sessions/', data: body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return WorkoutSessionModel.fromJson(response.data);
      }
      throw Exception(
        'Error al iniciar entrenamiento: Código ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        'Error al iniciar o recuperar entrenamiento: ${e.message}',
      );
    }
  }

  /// Registra una nueva serie (set) en el backend.
  Future<LogSetModel> saveSet(LogSetModel setLog) async {
    try {
      final response = await _dio.post('sets/', data: setLog.toJson());
      if (response.statusCode == 201) {
        return LogSetModel.fromJson(response.data);
      }
      throw Exception('Error al guardar serie: Código ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error al guardar la serie de ejercicio: ${e.message}');
    }
  }

  /// Actualiza una serie (set) existente en el backend.
  Future<LogSetModel> updateSet(LogSetModel setLog) async {
    try {
      final response = await _dio.put(
        'sets/${setLog.id}/',
        data: setLog.toJson(),
      );
      if (response.statusCode == 200) {
        return LogSetModel.fromJson(response.data);
      }
      throw Exception(
        'Error al actualizar serie: Código ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception('Error al actualizar la serie: ${e.message}');
    }
  }

  /// Elimina una serie (set) permanentemente según su [setId].
  Future<void> deleteSet(int setId) async {
    try {
      final response = await _dio.delete('sets/$setId/');
      if (response.statusCode != 204) {
        throw Exception(
          'Error al eliminar serie: Código ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        'Error al eliminar la serie de la base de datos: ${e.message}',
      );
    }
  }

  /// Obtiene las series del último entrenamiento realizado para un ejercicio específico.
  /// Útil para pre-llenar sugerencias de peso y repeticiones.
  Future<List<LogSetModel>> fetchLastExerciseLogs(int exerciseId) async {
    try {
      final response = await _dio.get('sets/exercise/$exerciseId/last/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => LogSetModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw Exception('Error al obtener sugerencias: ${e.message}');
    }
  }

  /// Obtiene el historial completo de entrenamientos realizados para un ejercicio específico.
  /// Retorna una lista de mapas con las fechas y las series realizadas.
  Future<List<Map<String, dynamic>>> fetchExerciseHistory(
    int exerciseId,
  ) async {
    try {
      final response = await _dio.get('sets/exercise/$exerciseId/history/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception(
        'Error al obtener historial: Código ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener el historial de este ejercicio: ${e.message}',
      );
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

    try {
      final response = await _dio.get(
        'sessions/history/',
        queryParameters: {
          'start_date': start,
          'end_date': end,
          'page': page,
          'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        return PaginatedWorkoutHistoryModel.fromJson(response.data);
      }
      throw Exception(
        'Error al obtener historial: Código ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw Exception(
        'Error al obtener el historial de entrenamientos: ${e.message}',
      );
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
