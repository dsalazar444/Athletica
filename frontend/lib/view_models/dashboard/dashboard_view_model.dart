import '../../models/dashboard/dashboard_model.dart';
import '../../repositories/dashboard/dashboard_repository.dart';

class DashboardViewModel {
  final DashboardRepository _repository = DashboardRepository();

  AthleteDashboardModel? athleteDashboard;
  CoachDashboardModel? coachDashboard;
  List<WeightLogModel> weightLogs = [];

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAthleteDashboard() async {
    isLoading = true;
    errorMessage = null;
    try {
      athleteDashboard = await _repository.getAthleteDashboard();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadCoachDashboard() async {
    isLoading = true;
    errorMessage = null;
    try {
      coachDashboard = await _repository.getCoachDashboard();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadWeightLogs() async {
    isLoading = true;
    errorMessage = null;
    try {
      weightLogs = await _repository.getWeightLogs();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
    }
  }

  Future<bool> addWeightLog(double weight, {double? bodyFat}) async {
    try {
      final log = await _repository.addWeightLog(weight, bodyFat: bodyFat);
      weightLogs.insert(0, log);
      if (athleteDashboard != null) {
        athleteDashboard = AthleteDashboardModel(
          height: athleteDashboard!.height,
          age: athleteDashboard!.age,
          gender: athleteDashboard!.gender,
          activityLevel: athleteDashboard!.activityLevel,
          latestWeight: log,
          goal: athleteDashboard!.goal,
        );
      }
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }
}
