/// Modelo que representa un ejercicio obtenido de una API externa (Wger).
/// Estos ejercicios se muestran en el catálogo al buscar para añadir a una rutina.
class ExerciseModel {
  /// Identificador único del ejercicio en el sistema externo.
  final int id;

  /// Nombre del ejercicio (ej. "Press de Banca").
  String name;

  /// Descripción detallada del movimiento y técnica.
  String description;

  /// Lista de IDs de los músculos trabajados (según el mapeo de Wger).
  final List<int> muscles;

  /// Indica si los textos actuales son originales (ej. Inglés) y requieren traducción.
  bool needsTranslation;

  /// URL de la imagen ilustrativa del ejercicio (se carga bajo demanda).
  String? imageUrl;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.muscles,
    this.needsTranslation = false,
    this.imageUrl,
  });

  /// Crea un [ExerciseModel] desde un mapa JSON de Wger.
  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    // Si la API ya devolvió un ejercicio traducido directamente.
    String rawName = json['name'] ?? 'Sin nombre';
    String rawDescription = json['description'] ?? '';

    // Si hay una lista de traducciones, buscamos específicamente la de español (id: 2).
    final translations = json['translations'] as List?;
    bool isOfficialSpanish = false;
    if (translations != null && translations.isNotEmpty) {
      final translation = translations.firstWhere(
        (t) => t['language'] == 2 || t['language_code'] == 'es',
        orElse: () => null,
      );
      if (translation != null) {
        rawDescription = translation['description'] ?? rawDescription;
        isOfficialSpanish = true;
      }
    }

    return ExerciseModel(
      id: json['id'],
      name: _stripHtml(rawName),
      description: _stripHtml(rawDescription),
      muscles: (json['muscles'] != null)
          ? (json['muscles'] as List).map((m) => m is int ? m : m['id'] as int).toList()
          : [],
      needsTranslation: !isOfficialSpanish,
    );
  }

  /// Elimina etiquetas HTML y decodifica entidades comunes de un string.
  static String _stripHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Elimina etiquetas <p>, <li>, etc.
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  /// Convierte el modelo a JSON para su persistencia en el backend local.
  Map<String, dynamic> toJson() => {
    'external_id': id,
    'name': name,
    'description': description,
    'muscle': primaryMuscleName,
    'image_url': imageUrl,
  };

  /// Diccionario estático de IDs de músculos a nombres legibles en español.
  static const Map<int, String> muscleNames = {
    1: 'Pecho', 2: 'Espalda', 3: 'Hombro anterior', 4: 'Hombro posterior',
    5: 'Tríceps', 6: 'Bíceps', 7: 'Glúteo mayor', 8: 'Glúteo medio',
    9: 'Recto femoral', 10: 'Vasto lateral', 11: 'Vasto medial',
    12: 'Semitendinoso', 13: 'Bíceps femoral', 14: 'Gastrocnemio',
    15: 'Sóleo', 16: 'Trapecio superior', 17: 'Trapecio medio',
    18: 'Trapecio inferior', 19: 'Romboides', 20: 'Erectores espinales',
    21: 'Abdominales rectos', 22: 'Oblicuos externos', 23: 'Oblicuos internos',
    24: 'Psoas-ilíaco', 25: 'Aductores de cadera', 26: 'Pectoral menor',
    27: 'Serrato anterior', 28: 'Subescapular', 29: 'Infraespinoso',
    30: 'Redondo mayor', 31: 'Redondo menor', 32: 'Supinador',
    33: 'Pronador', 34: 'Flexores de antebrazo', 35: 'Extensores de antebrazo',
    36: 'Bíceps braquial corto', 37: 'Bíceps braquial largo',
  };

  /// Convierte un ID de músculo de la API a su equivalente textual.
  static String muscleIdToString(int id) {
    return muscleNames[id] ?? 'Otro';
  }

  /// Propiedad calculada que retorna el nombre del primer músculo involucrado.
  String get primaryMuscleName {
    if (muscles.isEmpty) return 'Sin grupo muscular';
    return muscleIdToString(muscles.first);
  }
}
