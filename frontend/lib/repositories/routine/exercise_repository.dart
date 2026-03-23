import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../../models/routine/exercise_model.dart';
import '../../core/services/translation_service.dart';

/// Repositorio encargado de gestionar la obtención de ejercicios desde la API externa de Wger.
/// Maneja el catálogo de ejercicios, la recuperación de imágenes y su almacenamiento en caché.
class ExerciseRepository {
  /// Caché interna para evitar peticiones duplicadas a la API de imágenes.
  final Map<int, String?> _imageCache = {};

  /// URL base configurada para las peticiones al backend.
  final String baseUrl = ApiConfig.baseUrl;

  /// Servicio para traducciones automáticas.
  final TranslationService _translationService = TranslationService();

  /// Obtiene una lista paginada de ejercicios desde Wger.
  /// Los ejercicios se solicitan específicamente en español ([language: 2]).
  Future<List<ExerciseModel>> getExercises({
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.https("wger.de", "/api/v2/exerciseinfo/", {
      "limit": "$limit",
      "offset": "$offset",
      "language": "2", // 2: Español
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Error al cargar la lista de ejercicios de Wger.");
    }

    final data = jsonDecode(response.body);
    final List results = data['results'];

    // Convertimos la lista de resultados JSON en objetos ExerciseModel.
    final exercises = results.map((e) => ExerciseModel.fromJson(e)).toList();

    // Traducimos automáticamente la descripción si no tiene versión oficial en español.
    await Future.wait(exercises.map((ex) async {
      if (ex.needsTranslation) {
        final translatedDesc = await _translationService.translateToSpanish(ex.description);
        ex.description = translatedDesc;
        // El nombre se mantiene en inglés por preferencia del usuario.
        ex.needsTranslation = false;
      }
    }));

    return exercises;
  }

  /// Recupera las imágenes para una lista de IDs de ejercicios de forma secuencial.
  Future<Map<int, String?>> getExerciseImages(List<int> exerciseIds) async {
    final Map<int, String?> result = {};
    for (final id in exerciseIds) {
      try {
        result[id] = await getExerciseImage(id);
      } catch (e) {
        // Si falla una imagen, continuamos con las demás devolviendo null.
        result[id] = null;
      }
    }
    return result;
  }
  
  /// Obtiene la URL de la imagen principal para un ejercicio dado un su [id].
  /// Utiliza [_imageCache] para optimizar el rendimiento y reducir el tráfico de red.
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
      // Un error 400 en Wger a veces indica que no hay imágenes para ese ejercicio.
      _imageCache[id] = null;
      return null;
    } else {
      throw Exception(
        "Fallo al obtener la imagen del ejercicio $id. Código: ${response.statusCode}",
      );
    }
  }

  /// Asocia las URLs de las imágenes descargadas a sus respectivos modelos de ejercicio.
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
