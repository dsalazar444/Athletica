import 'package:dio/dio.dart';
import '../../models/routine/exercise_model.dart';
import '../../models/routine/routine_model.dart';
import '../../core/services/translation_service.dart';
import '../../core/api_client.dart';

/// Repositorio responsable de las operaciones CRUD de rutinas y la asociación de ejercicios.
class RoutineRepository {
  final String baseUrl;
  final TranslationService _translationService = TranslationService();
  final Dio _dio = ApiClient.dio;

  RoutineRepository({required this.baseUrl});

  /// Comprueba si un ejercicio ya existe en la base de datos local usando su [externalId].
  Future<bool> existsExercise(int externalId) async {
    try {
      final response = await _dio.get('exercises/', queryParameters: {'external_id': externalId});
      if (response.statusCode == 200) {
        return response.data['exists'] == true;
      }
      return false;
    } on DioException catch (e) {
      print('Error checking exercise existence: ${e.message}');
      return false;
    }
  }

  /// Crea un nuevo registro de ejercicio en el backend.
  Future<void> createExercise(ExerciseModel exercise) async {
    try {
      final response = await _dio.post('exercises/', data: exercise.toJson());
      if (response.statusCode == 201) return;
    } on DioException catch (e) {
      String errorMsg = 'Error al crear ejercicio';
      final errorData = e.response?.data;
      if (errorData is Map && errorData.isNotEmpty) {
        errorMsg = errorData.values.first is List
            ? errorData.values.first[0].toString()
            : errorData.values.first.toString();
      }
      throw Exception(errorMsg);
    }
  }

  /// Crea una rutina completa. Asegura que todos sus ejercicios existan antes de la persistencia.
  Future<RoutineModel> createRoutine(RoutineModel routine) async {
    // Verificación de integridad: el ejercicio debe existir en la BD local para ser asociado.
    for (final routineExercise in routine.exercises) {
      final exists = await existsExercise(routineExercise.exercise.id);
      if (!exists) {
        await createExercise(routineExercise.exercise);
      }
    }

    try {
      final response = await _dio.post('routines/', data: routine.toJson());
      if (response.statusCode == 201) {
        return RoutineModel.fromJson(response.data);
      }
      throw Exception('Error al crear rutina: Código ${response.statusCode}');
    } on DioException catch (e) {
      String errorMsg = 'Error al crear rutina';
      final errorData = e.response?.data;
      if (errorData is Map && errorData.isNotEmpty) {
        errorMsg = errorData.values.first is List
            ? errorData.values.first[0].toString()
            : errorData.values.first.toString();
      }
      throw Exception(errorMsg);
    }
  }

  /// Obtiene el listado de todas las rutinas registradas.
  Future<List<RoutineModel>> fetchRoutines() async {
    try {
      final response = await _dio.get('routines/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final routines = data.map((e) => RoutineModel.fromJson(e)).toList();
        
        // Traducir ejercicios si es necesario (para datos ya guardados en inglés)
        for (var routine in routines) {
          await _translateExercises(routine.exercises.map((re) => re.exercise).toList());
        }
        
        return routines;
      } else {
        throw Exception('Fallo al recuperar la lista de rutinas.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('No tienes permiso para ver las rutinas. Por favor, inicia sesión de nuevo.');
      }
      throw Exception('Error al conectar con el servidor: ${e.message}');
    }
  }

  /// Helper para traducir una lista de ejercicios.
  Future<void> _translateExercises(List<ExerciseModel> exercises) async {
    await Future.wait(exercises.map((ex) async {
      if (ex.needsTranslation) {
        final translatedDesc = await _translationService.translateToSpanish(ex.description);
        ex.description = translatedDesc;
        ex.needsTranslation = false;
      }
    }));
  }

  /// Obtiene los detalles de una rutina específica por su [routineId].
  Future<RoutineModel> fetchRoutineDetail(int routineId) async {
    try {
      final response = await _dio.get('routines/$routineId/');
      if (response.statusCode == 200) {
        final routine = RoutineModel.fromJson(response.data);
        
        // Traducir ejercicios si es necesario
        await _translateExercises(routine.exercises.map((re) => re.exercise).toList());
        
        return routine;
      } else {
        throw Exception('Fallo al recuperar los detalles de la rutina.');
      }
    } on DioException catch (e) {
      throw Exception('Error al recuperar detalles: ${e.message}');
    }
  }

  /// Elimina la relación entre un ejercicio y una rutina específica.
  Future<void> deleteRoutineExercise(int routineId, int exerciseId) async {
    try {
      final response = await _dio.delete('routines/$routineId/exercises/$exerciseId/');
      if (response.statusCode != 204) {
        throw Exception('No se pudo desvincular el ejercicio de la rutina.');
      }
    } on DioException catch (e) {
      throw Exception('Error al eliminar ejercicio de rutina: ${e.message}');
    }
  }
}
