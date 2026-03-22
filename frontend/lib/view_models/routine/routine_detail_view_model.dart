import 'package:flutter/material.dart';
import '../../models/routine/routine_model.dart';
import '../../models/routine/routine__exercise_model.dart';
import '../../repositories/routine/routine_repository.dart';

/// ViewModel que gestiona el estado de una rutina específica y sus ejercicios.
/// Permite refrescar la información de la rutina y eliminar ejercicios de la misma.
class RoutineDetailViewModel extends ChangeNotifier {
  final RoutineRepository routineRepository;
  RoutineModel routine;
  
  /// Indica si la aplicación está cargando información del servidor.
  bool isLoading = false;

  /// Almacena un mensaje de error si ocurre un fallo en una petición.
  String? errorMessage;

  RoutineDetailViewModel({
    required this.routineRepository,
    required this.routine,
  });

  /// Recarga el detalle de la rutina desde el backend para asegurar que la información sea actual.
  Future<void> refreshRoutine() async {
    if (routine.id == null) return;
    isLoading = true;
    notifyListeners();
    try {
      routine = await routineRepository.fetchRoutineDetail(routine.id!);
      errorMessage = null;
    } catch (e) {
      errorMessage = "No se pudo actualizar la rutina.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina un ejercicio específico de la rutina por su [exerciseId].
  /// Implementa una actualización optimista de la interfaz antes de confirmar con el backend.
  Future<void> removeExercise(int exerciseId) async {
    if (routine.id == null) return;
    
    // Almacenamos el estado original para hacer rollback en caso de error.
    final List<RoutineExerciseModel> originalExercises = List.from(routine.exercises);

    // Actualización optimista: removemos el ejercicio de la lista local de inmediato.
    routine.exercises.removeWhere((e) => e.exercise.id == exerciseId);
    notifyListeners();

    try {
      // Intentamos la eliminación persistente en el backend.
      await routineRepository.deleteRoutineExercise(routine.id!, exerciseId);
      
      // Si tiene éxito, refrescamos detalles (por ejemplo, para actualizar números de orden).
      await refreshRoutine();
    } catch (e) {
      // En caso de fallo, restauramos los datos originales y notificamos el error.
      routine.exercises.clear();
      routine.exercises.addAll(originalExercises);
      errorMessage = "Error al eliminar ejercicio de la rutina. Por favor, intenta de nuevo.";
      notifyListeners();
    }
  }
}
