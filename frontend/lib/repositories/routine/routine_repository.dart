import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/routine/exercise_model.dart';
import '../../models/routine/routine_model.dart';
import '../../core/services/translation_service.dart';

/// Repositorio responsable de las operaciones CRUD de rutinas y la asociación de ejercicios.
class RoutineRepository {
  final String baseUrl;
  final TranslationService _translationService = TranslationService();

  RoutineRepository({required this.baseUrl});

  /// Comprueba si un ejercicio ya existe en la base de datos local usando su [externalId].
  Future<bool> existsExercise(int externalId) async {
    final response = await http.get(Uri.parse('$baseUrl/exercises/?external_id=$externalId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['exists'] == true;
    } else {
      throw Exception('Fallo en la verificación de existencia del ejercicio: $externalId');
    }
  }

  /// Crea un nuevo registro de ejercicio en el backend.
  Future<void> createExercise(ExerciseModel exercise) async {
    final response = await http.post(
      Uri.parse('$baseUrl/exercises/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(exercise.toJson()),
    );

    if (response.statusCode == 201) return;

    // Manejo de errores detallados provenientes de la API.
    String errorMsg = 'Error al crear ejercicio';
    try {
      final errorJson = json.decode(response.body);
      if (errorJson is Map && errorJson.isNotEmpty) {
        errorMsg = errorJson.values.first is List
            ? errorJson.values.first[0].toString()
            : errorJson.values.first.toString();
      }
    } catch (_) {
      errorMsg = response.body;
    }
    throw Exception(errorMsg);
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

    final response = await http.post(
      Uri.parse('$baseUrl/routines/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(routine.toJson()),
    );

    if (response.statusCode == 201) {
      return RoutineModel.fromJson(json.decode(response.body));
    }

    String errorMsg = 'Error al crear rutina';
    try {
      final errorJson = json.decode(response.body);
      if (errorJson is Map && errorJson.isNotEmpty) {
        errorMsg = errorJson.values.first is List
            ? errorJson.values.first[0].toString()
            : errorJson.values.first.toString();
      }
    } catch (_) {
      errorMsg = response.body;
    }
    throw Exception(errorMsg);
  }

  /// Obtiene el listado de todas las rutinas registradas.
  Future<List<RoutineModel>> fetchRoutines() async {
    final response = await http.get(Uri.parse('$baseUrl/routines/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final routines = data.map((e) => RoutineModel.fromJson(e)).toList();
      
      // Traducir ejercicios si es necesario (para datos ya guardados en inglés)
      for (var routine in routines) {
        await _translateExercises(routine.exercises.map((re) => re.exercise).toList());
      }
      
      return routines;
    } else {
      throw Exception('Fallo al recuperar la lista de rutinas.');
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
    final response = await http.get(Uri.parse('$baseUrl/routines/$routineId/'));
    if (response.statusCode == 200) {
      final routine = RoutineModel.fromJson(json.decode(response.body));
      
      // Traducir ejercicios si es necesario
      await _translateExercises(routine.exercises.map((re) => re.exercise).toList());
      
      return routine;
    } else {
      throw Exception('Fallo al recuperar los detalles de la rutina.');
    }
  }

  /// Elimina la relación entre un ejercicio y una rutina específica.
  Future<void> deleteRoutineExercise(int routineId, int exerciseId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/routines/$routineId/exercises/$exerciseId/'),
    );
    if (response.statusCode != 204) {
      throw Exception('No se pudo desvincular el ejercicio de la rutina.');
    }
  }
}
