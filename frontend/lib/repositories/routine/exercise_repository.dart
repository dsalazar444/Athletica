import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/routine/exercise_model.dart';

class ExerciseRepository {
  final Map<int, String?> _imageCache = {};

  final uri = Uri.https("wger.de", "/api/v2/exerciseinfo/", {
    "limit": "20",
    "language": "2",
    "offset": "0",
  });

  Future<List<ExerciseModel>> getExercises({
    int limit = 20,
    int offset = 0,
  }) async {
    print('Entrando a getExerciseImages con:');

    final uri = Uri.https("wger.de", "/api/v2/exerciseinfo/", {
      "limit": "$limit",
      "offset": "$offset",
      "language": "2", // spanish
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) throw Exception("Error al cargar ejercicios");

    final data = jsonDecode(response.body);
    final List results = data['results'];

    // result es una lista con los 20 ejercicios, entonces los recorremos y los convertimos a ExerciseModel
    print("termine de trar exercises, data.result: $results");

    return results.map((e) => ExerciseModel.fromJson(e)).toList();
  }

  Future<Map<int, String?>> getExerciseImages(List<int> exerciseIds) async {
    final results = await Future.wait(
      exerciseIds.map((id) async => MapEntry(id, await getExerciseImage(id))),
    );
    return Map.fromEntries(results);
  }
  
  Future<String?> getExerciseImage(int id) async {

    if (_imageCache.containsKey(id)) {
      return _imageCache[id];
    }

    final uri = Uri.https("wger.de", "/api/v2/exerciseimage/", {
      "exercise": id.toString(),
      "limit": "1",
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body)['results'] as List;
      final imageUrl = data.isNotEmpty ? data[0]['image'] as String : null;
      _imageCache[id] = imageUrl;

      return imageUrl;

    } else if (response.statusCode == 400) {

      _imageCache[id] = null;
      return null;

    } else {

      throw Exception(
        "Error al cargar imagen para ejercicio $id. Status: ${response.statusCode}. Body: ${response.body}",
      );
    }
  }

  List<ExerciseModel> combineExercisesWithImages(
    List<ExerciseModel> exercises,
    Map<int, String?> images,
  ) {
    for (var ex in exercises) {
      ex.imageUrl = images[ex.id];
    }
    return exercises;
  }
}
