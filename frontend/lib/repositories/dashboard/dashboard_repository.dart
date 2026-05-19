import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../models/dashboard/dashboard_model.dart';

class DashboardRepository {
  final Dio _dio = ApiClient.dio;

  Future<AthleteDashboardModel> getAthleteDashboard() async {
    final response = await _dio.get('dashboard/athlete/');
    return AthleteDashboardModel.fromJson(response.data);
  }

  Future<CoachDashboardModel> getCoachDashboard() async {
    final response = await _dio.get('dashboard/coach/');
    return CoachDashboardModel.fromJson(response.data);
  }

  Future<List<WeightLogModel>> getWeightLogs() async {
    final response = await _dio.get('athlete/weight-logs/');
    return (response.data as List)
        .map((w) => WeightLogModel.fromJson(w))
        .toList();
  }

  Future<WeightLogModel> addWeightLog(
    double weight, {
    double? bodyFat,
    String? date,
  }) async {
    final response = await _dio.post(
      'athlete/weight-logs/',
      data: {'weight': weight, 'body_fat': bodyFat, 'date': date},
    );
    return WeightLogModel.fromJson(response.data);
  }

  Future<void> createGroup(String name) async {
    final response = await _dio.post('coach/groups/', data: {'name': name});

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error creando grupo');
    }
  }

  Future<List<GoalModel>> getGoals() async {
    final response = await _dio.get('athlete/goals/');
    return (response.data as List).map((g) => GoalModel.fromJson(g)).toList();
  }

  Future<GoalModel> createGoal({
    required String goalType,
    String? description,
    double? targetValue,
    double? currentValue,
    String? deadline,
  }) async {
    final response = await _dio.post(
      'athlete/goals/',
      data: {
        'goal_type': goalType,
        'description': description ?? '',
        'target_value': targetValue,
        'current_value': currentValue,
        'deadline': deadline,
      },
    );
    return GoalModel.fromJson(response.data);
  }

  Future<GoalModel> updateGoal(
    int id, {
    String? goalType,
    String? description,
    double? targetValue,
    double? currentValue,
    String? deadline,
    bool? isActive,
  }) async {
    final response = await _dio.put(
      'athlete/goals/$id/',
      data: {
        'goal_type': goalType,
        'description': description,
        'target_value': targetValue,
        'current_value': currentValue,
        'deadline': deadline,
        'is_active': isActive,
      },
    );
    return GoalModel.fromJson(response.data);
  }

  Future<void> deleteGoal(int id) async {
    await _dio.delete('athlete/goals/$id/');
  }
}
