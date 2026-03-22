import 'package:flutter/material.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../models/routine/routine_model.dart';

class RoutinesListViewModel extends ChangeNotifier {
  final RoutineRepository routineRepository;

  bool isLoading = false;
  String? errorMessage;
  List<RoutineModel> routines = [];

  RoutinesListViewModel({required this.routineRepository});

  Future<void> loadRoutines() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      routines = await routineRepository.fetchRoutines();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
