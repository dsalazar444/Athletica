class StatItem {
  final num current;
  final num previous;
  final double changePercentage;

  StatItem({
    required this.current,
    required this.previous,
    required this.changePercentage,
  });

  factory StatItem.fromJson(Map<String, dynamic> json) {
    return StatItem(
      current: json['current'] ?? 0,
      previous: json['previous'] ?? 0,
      changePercentage: (json['change_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ComparativeStatsModel {
  final StatItem workouts;
  final StatItem caloriesDailyAvg;
  final StatItem weightAvg;

  ComparativeStatsModel({
    required this.workouts,
    required this.caloriesDailyAvg,
    required this.weightAvg,
  });

  factory ComparativeStatsModel.fromJson(Map<String, dynamic> json) {
    return ComparativeStatsModel(
      workouts: StatItem.fromJson(json['workouts'] ?? {}),
      caloriesDailyAvg: StatItem.fromJson(json['calories_daily_avg'] ?? {}),
      weightAvg: StatItem.fromJson(json['weight_avg'] ?? {}),
    );
  }
}
