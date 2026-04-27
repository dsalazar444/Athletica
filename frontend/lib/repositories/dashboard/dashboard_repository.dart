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

  Future<WeightLogModel> addWeightLog(double weight, {double? bodyFat}) async {
    final response = await _dio.post(
      'athlete/weight-logs/',
      data: {
        'weight': weight,
        'body_fat': bodyFat,
      },
    );
    return WeightLogModel.fromJson(response.data);
  }
}
