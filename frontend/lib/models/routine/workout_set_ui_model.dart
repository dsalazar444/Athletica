import 'set_log_model.dart';

class WorkoutSetUiModel {
  /// Modelo base que se usa en flujo 'detalles > modificar rutina', pues este permite también ingresar reps y pesos.
  final LogSetModel base;

  /// Atributo adicional necesario para manejar UI (colores/checks/estado visual).
  final bool isCompleted;

  /// Campo extra que te pidieron (ejemplo: RIR).
  /// Cámbialo por el nombre/tipo real que te hayan solicitado.
  final int? rir;

  const WorkoutSetUiModel({
    required this.base,
    this.isCompleted = false,
    this.rir,
  });

  /// Helpers para no escribir base.reps/base.weight todo el tiempo en UI.
  int get reps => base.reps;
  double get weightKg => base.weight;
  int get setNumber => base.setNumber;
  int get exerciseId => base.exerciseId;
  int? get id => base.id;
  int? get sessionId => base.sessionId;

  WorkoutSetUiModel copyWith({
    LogSetModel? base,
    bool? isCompleted,
    int? rir,
    bool clearRir = false,
  }) {
    return WorkoutSetUiModel(
      base: base ?? this.base,
      isCompleted: isCompleted ?? this.isCompleted,
      rir: clearRir ? null : (rir ?? this.rir),
    );
  }

  /// Constructor cómodo desde el modelo persistente.
  factory WorkoutSetUiModel.fromWorkoutSet(
    LogSetModel set, {
    bool isCompleted = false,
    int? rir,
  }) {
    return WorkoutSetUiModel(base: set, isCompleted: isCompleted, rir: rir);
  }

  /// Para guardar en backend: solo devuelve el modelo persistente.
  LogSetModel toLogSetModel() => base;
}
