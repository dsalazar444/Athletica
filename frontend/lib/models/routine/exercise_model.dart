/// Model representing an exercise fetched from an external API (wger).
/// These exercises are displayed when searching for exercises in the 'Create Routine' feature.
class ExerciseModel {
  final int id;
  final String name;
  final String description;
  final List<int> muscles;
  String? imageUrl;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.muscles,
    this.imageUrl,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    final translations = json['translations'] as List?;

    Map<String, dynamic>? translation;

    if (translations != null && translations.isNotEmpty) {
      translation = translations.firstWhere(
        (t) => t['language'] == 2,
        orElse: () => translations[0],
      );
    }
    // No retornamos urlImage desde formjson (acá) porque la llamada de getExercise, que es con la que se crean los ExerciseModel, en repository no trae las imagenes, toca hacer otra llamada, y cuando ya las traen, ahi si se le asigna la imageUrl a cada ExerciseModel, en combineExercise...
    return ExerciseModel(
      id: json['id'],
      name: translation?['name'] ?? 'Sin nombre',
      description: translation?['description'] ?? '',
      muscles: (json['muscles'] != null)
          ? (json['muscles'] as List).map((m) => m is int ? m : m['id'] as int).toList()
          : [],
    );
    //ejemplo de retorno de objeto en llamada api:
    // {
    //   "id": 123,
    //   "name": "Press de Banca",
    //   "description": "...",
    //   "muscles": [ {"id": 1, ...}, {"id": 2, ...} ]
    // }
  }

  // convierte objeto de gui a json
  Map<String, dynamic> toJson() => {
    'external_id': id,
    'name': name,
    'description': description,
    'muscle': primaryMuscleName,
    'imageUrl': imageUrl,
  };
  /// Mapa de IDs de músculos a nombres en español
  static const Map<int, String> muscleNames = {
    1: 'Pecho',
    2: 'Espalda',
    3: 'Hombro anterior',
    4: 'Hombro posterior',
    5: 'Tríceps',
    6: 'Bíceps',
    7: 'Glúteo mayor',
    8: 'Glúteo medio',
    9: 'Recto femoral',
    10: 'Vasto lateral',
    11: 'Vasto medial',
    12: 'Semitendinoso',
    13: 'Bíceps femoral',
    14: 'Gastrocnemio',
    15: 'Sóleo',
    16: 'Trapecio superior',
    17: 'Trapecio medio',
    18: 'Trapecio inferior',
    19: 'Romboides',
    20: 'Erectores espinales',
    21: 'Abdominales rectos',
    22: 'Oblicuos externos',
    23: 'Oblicuos internos',
    24: 'Psoas-ilíaco',
    25: 'Aductores de cadera',
    26: 'Pectoral menor',
    27: 'Serrato anterior',
    28: 'Subescapular',
    29: 'Infraespinoso',
    30: 'Redondo mayor',
    31: 'Redondo menor',
    32: 'Supinador',
    33: 'Pronador',
    34: 'Flexores de antebrazo',
    35: 'Extensores de antebrazo',
    36: 'Bíceps braquial corto',
    37: 'Bíceps braquial largo',
  };

  /// Devuelve el nombre del músculo dado su id (según la API de wger)
  static String muscleIdToString(int id) {
    return muscleNames[id] ?? 'Otro';
  }

  /// Devuelve el nombre del primer músculo de la lista, o 'Sin grupo muscular' si está vacía
  String get primaryMuscleName {
    if (muscles.isEmpty) return 'Sin grupo muscular';
    return muscleIdToString(muscles.first);
  }
}
