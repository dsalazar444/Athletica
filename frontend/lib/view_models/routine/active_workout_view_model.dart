import 'package:flutter/foundation.dart';

import '../../models/routine/active_exercise_model.dart';
import '../../models/routine/routine__exercise_model.dart';
import '../../models/routine/set_log_model.dart';
import '../../models/routine/workout_session_model.dart';
import '../../models/routine/workout_set_ui_model.dart';
import '../../repositories/routine/workout_repository.dart';

class ActiveWorkoutViewModel extends ChangeNotifier {
  static const int defaultSetCount = 3;
  static const int defaultRestSeconds = 90;
  static const int defaultReps = 0;
  static const double defaultWeight = 0;

  final WorkoutRepository workoutRepository;

  WorkoutSessionModel? currentSession;
  bool isSaving = false;
  String? errorMessage;

  ActiveWorkoutViewModel({required this.workoutRepository});

  // Usamos valores predeterminados de setcount (porque actualmente no se guarda en bd, mejora para siguiente sprint -> pedir dato al crear rutina)
  // y de defaultReps y defaultWeight para en siguiente sprint que estos se tomen desde backend y se muestre el ultimo valor de sus registros.
  List<ActiveExerciseModel> toActiveExercises(
    List<RoutineExerciseModel> routineExercises, {
    int defaultSetCount = ActiveWorkoutViewModel.defaultSetCount,
    int defaultRestSeconds = ActiveWorkoutViewModel.defaultRestSeconds,
    int defaultReps = ActiveWorkoutViewModel.defaultReps,
    double defaultWeight = ActiveWorkoutViewModel.defaultWeight,
  }) {
    final ordered = [...routineExercises]
      ..sort((a, b) => a.order.compareTo(b.order));

    return ordered.map((re) {
      final sets = List.generate(
        defaultSetCount,
        (index) => WorkoutSetUiModel(
          base: LogSetModel(
            exerciseId: re.exercise.id,
            setNumber: index + 1,
            reps: defaultReps,
            weight: defaultWeight,
          ),
        ),
      );

      return ActiveExerciseModel(
        exercise: re.exercise,
        restSeconds: defaultRestSeconds,
        sets: sets,
      );
    }).toList();
  }

  Future<void> initSession({required int routineId, DateTime? date}) async {
    errorMessage = null;
    try {
      currentSession = await workoutRepository.startSession(
        routineId,
        date: date,
      );
    } catch (e) {
      errorMessage = 'No se pudo iniciar la sesión de entrenamiento.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> saveAll({required List<List<WorkoutSetUiModel>> allSets}) async {
    final sessionId = currentSession?.id;
    if (sessionId == null) {
      throw Exception('No hay sesión activa para guardar.');
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1) Guardar/actualizar sets actuales
      final flatSets = allSets.expand((group) => group).toList();

      for (final uiSet in flatSets) {
        final payload = uiSet.base.copyWith(sessionId: sessionId);

        if (payload.id == null) {
          await workoutRepository.saveSet(payload);
        } else {
          await workoutRepository.updateSet(payload);
        }
      }
    } catch (e) {
      errorMessage = 'No se pudieron guardar los datos del entrenamiento.';
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Orquesta el cierre del entrenamiento:
  /// 1) asegura sesión activa, 2) persiste todas las series.
  Future<void> finishWorkout({
    required int routineId,
    required List<List<WorkoutSetUiModel>> allSets,
    DateTime? date,
  }) async {
    errorMessage = null;
    try {
      if (currentSession?.id == null) {
        await initSession(routineId: routineId, date: date);
      }

      await saveAll(allSets: allSets);
    } catch (e) {
      errorMessage =
          errorMessage ?? 'No se pudo finalizar y guardar el entrenamiento.';
      notifyListeners();
      rethrow;
    }
  }
}
