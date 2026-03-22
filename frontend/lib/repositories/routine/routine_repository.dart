
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/routine/exercise_model.dart';
import '../../models/routine/routine_model.dart';

class RoutineRepository {
	final String baseUrl;

	RoutineRepository({required this.baseUrl});

	Future<bool> existsExercise(int externalId) async {
		final response = await http.get(Uri.parse('$baseUrl/exercises/?external_id=$externalId'));
		if (response.statusCode == 200) {
			final data = json.decode(response.body);
			return data['exists'] == true;
		} else {
			throw Exception('Error al verificar ejercicio: $externalId');
		}
	}

	Future<void> createExercise(ExerciseModel exercise) async {
		final response = await http.post(
			Uri.parse('$baseUrl/exercises/'),
			headers: {'Content-Type': 'application/json'},
			body: json.encode(exercise.toJson()),
		);

		if (response.statusCode == 201) {
			// Creado correctamente
			return;
		}
		// Intenta extraer mensaje de error del JSON
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

  Future<RoutineModel> createRoutine(RoutineModel routine) async {
		// Verifica que todos los ejercicios existen antes de crear la rutina
		for (final routineExercise in routine.exercises) {
			final exists = await existsExercise(routineExercise.exercise.id);
			if (!exists) {
				await createExercise(routineExercise.exercise);
			}
		}
		print('*****************************************');
		print('url final create routine es ${baseUrl}/routines/');
		print('routine JSON: ${json.encode(routine.toJson())}');

		final response = await http.post(
			Uri.parse('$baseUrl/routines/'),
			headers: {'Content-Type': 'application/json'},
			body: json.encode(routine.toJson()),
		);
		if (response.statusCode == 201) {
			return RoutineModel.fromJson(json.decode(response.body));
		}
		// Intenta extraer mensaje de error del JSON
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

	Future<List<RoutineModel>> fetchRoutines() async {
		final response = await http.get(Uri.parse('$baseUrl/routines/'));
		if (response.statusCode == 200) {
			final List<dynamic> data = json.decode(response.body);
			return data.map((e) => RoutineModel.fromJson(e)).toList();
		} else {
			throw Exception('Error al obtener rutinas');
		}
	}

	
}
