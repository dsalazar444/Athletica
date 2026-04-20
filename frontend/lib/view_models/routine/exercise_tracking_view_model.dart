import 'package:flutter/material.dart';
import '../../models/routine/set_log_model.dart';
import '../../models/routine/workout_session_model.dart';
import '../../repositories/routine/workout_repository.dart';

/// ViewModel que gestiona la lógica de seguimiento de un ejercicio en tiempo real.
/// Maneja la creación de sesiones, carga de registros previos, sugerencias de peso/reps,
/// y la sincronización (creación/actualización/eliminación) de series con el backend.
class ExerciseTrackingViewModel extends ChangeNotifier {
  final WorkoutRepository workoutRepository;
  final int exerciseId;
  final int routineId;

  /// La sesión de entrenamiento actual (se crea o reutiliza según la fecha).
  WorkoutSessionModel? currentSession;

  /// Las series registradas en la última sesión realizada (usado para sugerencias).
  List<SetLogModel> lastSessionSets = [];

  /// Lista interactiva de series que el usuario está registrando/editando actualmente.
  List<SetLogModel> setsToLog = [];

  /// Lista de IDs de series que han sido eliminadas de la UI y deben borrarse del backend al guardar.
  List<int> setsToDelete = [];

  /// Indica si los datos iniciales se están cargando desde el servidor.
  bool isLoading = false;

  /// Indica si se está realizando el proceso de guardado persistente.
  bool isSaving = false;

  /// Mensaje de error para retroalimentación al usuario.
  String? errorMessage;

  /// Fecha para la cual se están registrando los ejercicios.
  DateTime selectedDate;

  ExerciseTrackingViewModel({
    required this.workoutRepository,
    required this.exerciseId,
    required this.routineId,
    DateTime? initialDate,
  }) : selectedDate = initialDate ?? DateTime.now();

  /// Inicializa el estado del tracking:
  /// 1. Crea o recupera una sesión para la fecha seleccionada.
  /// 2. Busca registros históricos para el ejercicio y la fecha específica.
  /// 3. Si hay registros, los carga para edición; si no, genera sugerencias basadas en el último entreno.
  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    setsToDelete.clear();

    try {
      // 1. Iniciamos/Recuperamos la sesión de entrenamiento.
      currentSession = await workoutRepository.startSession(
        routineId,
        date: selectedDate,
      );

      // 2. Revisamos el historial para ver si ya se guardaron ejercicios este día.
      final history = await workoutRepository.fetchExerciseHistory(exerciseId);
      final dateKey =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      final existingDay = history.firstWhere(
        (day) => day['date'] == dateKey,
        orElse: () => {'sets': []},
      );

      final existingSets = (existingDay['sets'] as List)
          .map((s) => SetLogModel.fromJson(s))
          .toList();

      // 3. Obtenemos sugerencias del entrenamiento más reciente.
      lastSessionSets = await workoutRepository.fetchLastExerciseLogs(
        exerciseId,
      );

      // 4. Inicializamos las filas de la tabla de tracking.
      if (existingSets.isNotEmpty) {
        // Editamos registros ya existentes.
        setsToLog = existingSets;
      } else {
        // Iniciamos con solo 1 serie sugerida o vacía (como solicitó el usuario).
        final lastSet = lastSessionSets.isNotEmpty ? lastSessionSets.first : null;
        setsToLog = [
          SetLogModel(
            exerciseId: exerciseId,
            setNumber: 1,
            reps: lastSet?.reps ?? 10,
            weight: lastSet?.weight ?? 0.0,
            sessionId: currentSession?.id,
          )
        ];
      }
    } catch (e) {
      errorMessage = "Error al inicializar el registro del ejercicio.";
      debugPrint("Error en TrackingViewModel init: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia la fecha de registro y dispara una reinicialización de los datos.
  void setDate(DateTime date) {
    selectedDate = date;
    setsToLog = [];
    init();
  }

  /// Actualiza los valores de una serie específica en la lista local antes de guardar.
  void updateSet(int index, {int? reps, double? weight}) {
    if (index >= 0 && index < setsToLog.length) {
      setsToLog[index] = setsToLog[index].copyWith(
        reps: reps ?? setsToLog[index].reps,
        weight: weight ?? setsToLog[index].weight,
      );
      notifyListeners();
    }
  }

  /// Añade una nueva fila de serie a la tabla, basándose en la última serie existente.
  void addRow() {
    final lastSet = setsToLog.isNotEmpty ? setsToLog.last : null;
    setsToLog.add(
      SetLogModel(
        exerciseId: exerciseId,
        setNumber: setsToLog.length + 1,
        reps: lastSet?.reps ?? 10,  // Copia la serie anterior
        weight: lastSet?.weight ?? 0.0, // Copia la serie anterior
        sessionId: currentSession?.id,
      ),
    );
    notifyListeners();
  }

  /// Quita una serie de la lista local. Si ya existía en el backend, la marca para eliminación.
  void removeRow(int index) {
    if (index >= 0 && index < setsToLog.length) {
      final removed = setsToLog.removeAt(index);
      if (removed.id != null) {
        setsToDelete.add(removed.id!);
      }
      // Re-numeramos los números de serie para que sean consecutivos.
      for (int i = 0; i < setsToLog.length; i++) {
        setsToLog[i] = setsToLog[i].copyWith(setNumber: i + 1);
      }
      notifyListeners();
    }
  }

  /// Sincroniza todos los cambios locales con el backend de forma masiva:
  /// 1. Elimina las series marcadas para borrar.
  /// 2. Crea las nuevas (sin ID) o actualiza las modificadas (con ID).
  Future<void> saveAll() async {
    isSaving = true;
    notifyListeners();
    try {
      // 1. Eliminamos las series quitadas por el usuario.
      for (int id in setsToDelete) {
        await workoutRepository.deleteSet(id);
      }
      setsToDelete.clear();

      // 2. Persistimos (POST) o Actualizamos (PUT) las series restantes.
      for (var set in setsToLog) {
        if (set.id == null) {
          // Nueva serie: Crear en el servidor.
          await workoutRepository.saveSet(
            set.copyWith(sessionId: currentSession?.id),
          );
        } else {
          // Serie existente: Actualizar en el servidor.
          await workoutRepository.updateSet(
            set.copyWith(sessionId: currentSession?.id),
          );
        }
      }
    } catch (e) {
      errorMessage =
          "Fallo al sincronizar los datos de entrenamiento con el servidor.";
      debugPrint("Error guardando series: $e");
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
