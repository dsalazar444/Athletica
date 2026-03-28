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

  RoutinesListViewModel({required this.routineRepository});

  /// Carga la lista completa de rutinas desde el backend.
  /// Maneja los estados de carga y errores de forma automatizada.
  Future<void> loadRoutines() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      routines = await routineRepository.fetchRoutines();
    } catch (e) {
      errorMessage =
          "No se pudieron cargar las rutinas. Por favor, revisa tu conexión.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
