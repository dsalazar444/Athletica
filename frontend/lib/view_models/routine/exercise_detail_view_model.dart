import 'package:flutter/material.dart';
import '../../repositories/routine/workout_repository.dart';

/// ViewModel que gestiona la vista de detalles históricos e indicadores de un ejercicio.
/// Se encarga de recuperar el historial completo de sesiones y calcular récords personales.
class ExerciseDetailViewModel extends ChangeNotifier {
  final WorkoutRepository workoutRepository;
  final int exerciseId;

  /// Lista de sesiones pasadas obtenidas desde el backend para este ejercicio.
  List<Map<String, dynamic>> history = [];
  
  /// Estado que indica si se están cargando datos desde el servidor.
  bool isLoading = false;

  /// Almacena un mensaje de error si la carga falla.
  String? errorMessage;

  ExerciseDetailViewModel({
    required this.workoutRepository,
    required this.exerciseId,
  });

  /// Inicializa el ViewModel realizando la petición del historial al repositorio.
  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      history = await workoutRepository.fetchExerciseHistory(exerciseId);
    } catch (e) {
      errorMessage = "No se pudo cargar el historial del ejercicio. Reinténtalo más tarde.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Calcula dinámicamente el récord personal (máximo peso registrado) a partir del historial.
  /// Retorna un mapa con 'weight' y 'reps' del mejor levantamiento, o null si no hay datos.
  Map<String, dynamic>? get bestRecord {
    if (history.isEmpty) return null;
    double maxWeight = 0;
    int bestReps = 0;
    
    for (var session in history) {
      if (session['sets'] == null) continue;
      for (var s in (session['sets'] as List)) {
        // Intento de conversión segura del peso de la serie.
        double w = double.tryParse(s['weight']?.toString() ?? '0') ?? 0;
        if (w > maxWeight) {
          maxWeight = w;
          bestReps = s['reps'] ?? 0;
        }
      }
    }
    return maxWeight > 0 ? {'weight': maxWeight, 'reps': bestReps} : null;
  }
}
