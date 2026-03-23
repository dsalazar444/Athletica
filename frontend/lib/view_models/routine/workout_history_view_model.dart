import 'package:flutter/material.dart';

import '../../models/routine/workout_history_item_model.dart';
import '../../repositories/routine/workout_repository.dart';

/// ViewModel para gestionar el historial paginado de entrenamientos.
class WorkoutHistoryViewModel extends ChangeNotifier {
  final WorkoutRepository workoutRepository;

  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;

  DateTimeRange selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  List<WorkoutHistoryItemModel> sessions = [];

  int _page = 1;
  final int _pageSize = 10;
  bool hasNextPage = false;

  WorkoutHistoryViewModel({required this.workoutRepository});

  Future<void> init() async {
    await loadHistory(reset: true);
  }

  Future<void> setDateRange(DateTimeRange range) async {
    selectedRange = range;
    await loadHistory(reset: true);
  }

  Future<void> loadHistory({bool reset = false}) async {
    if (reset) {
      isLoading = true;
      errorMessage = null;
      _page = 1;
      sessions = [];
      notifyListeners();
    } else {
      if (!hasNextPage || isLoadingMore || isLoading) return;
      isLoadingMore = true;
      notifyListeners();
    }

    try {
      final response = await workoutRepository.fetchWorkoutHistoryByDateRange(
        startDate: selectedRange.start,
        endDate: selectedRange.end,
        page: _page,
        pageSize: _pageSize,
      );

      if (reset) {
        sessions = response.results;
      } else {
        sessions = [...sessions, ...response.results];
      }

      hasNextPage = response.next != null;
      _page += 1;
    } catch (e) {
      errorMessage = 'No se pudo cargar el historial de entrenamientos.';
    } finally {
      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    await loadHistory(reset: false);
  }
}
