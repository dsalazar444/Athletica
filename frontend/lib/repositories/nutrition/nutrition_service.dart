import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/nutrition/meal_record.dart';

class NutritionService {
  Future<List<MealRecord>> getMeals({String? date, int? athleteId}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date;
    if (athleteId != null) queryParams['athlete'] = athleteId;

    final response = await ApiClient.dio.get(
      'nutrition/meals/',
      queryParameters: queryParams,
    );

    final List<dynamic> data = response.data;
    return data.map((json) => MealRecord.fromJson(json)).toList();
  }

  Future<MealRecord> createMeal(MealRecord meal) async {
    final response = await ApiClient.dio.post(
      'nutrition/meals/',
      data: meal.toJson(),
    );
    return MealRecord.fromJson(response.data);
  }

  Future<void> deleteMeal(int id) async {
    await ApiClient.dio.delete('nutrition/meals/$id/');
  }
}