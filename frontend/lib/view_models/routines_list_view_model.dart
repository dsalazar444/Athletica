import 'package:flutter/material.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../models/routine/routine_model.dart';

/// ViewModel para la pantalla principal que lista las rutinas.
/// Gestiona la carga de la lista de rutinas desde el repositorio y notifica a la UI.
class RoutinesListViewModel extends ChangeNotifier {
  final RoutineRepository routineRepository;

  /// Estado de carga para mostrar un indicador en la pantalla.
  bool isLoading = false;

  /// Mensaje de error para notificar al usuario en caso de fallos.
  String? errorMessage;

  /// La lista de las rutinas obtenidas de la base de datos.
  List<RoutineModel> routines = [];

  /// La rutina activa asignada por el coach (solo para atletas).
  RoutineModel? activeRoutine;

  RoutinesListViewModel({required this.routineRepository});

  /// Carga la lista completa de rutinas desde el backend.
  Future<void> loadRoutines({int? athleteId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Cargar mis rutinas
      routines = await routineRepository.fetchRoutines();
      
      // Si soy atleta, cargar mi rutina activa
      if (athleteId != null) {
        try {
          activeRoutine = await routineRepository.fetchAthleteActiveRoutine(athleteId);
        } catch (e) {
          activeRoutine = null;
        }
      }
    } catch (e) {
      errorMessage = "No se pudieron cargar las rutinas. Por favor, revisa tu conexión.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
