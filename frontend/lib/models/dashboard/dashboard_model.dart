class AthleteDashboardModel {
  final double height;
  final int age;
  final String gender;
  final String activityLevel;
  final WeightLogModel? latestWeight;
  final GoalModel? goal;

  AthleteDashboardModel({
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
    this.latestWeight,
    this.goal,
  });

  factory AthleteDashboardModel.fromJson(Map<String, dynamic> json) {
    return AthleteDashboardModel(
      height: (json['height'] as num).toDouble(),
      age: json['age'],
      gender: json['gender'],
      activityLevel: json['activity_level'],
      latestWeight: json['latest_weight'] != null
          ? WeightLogModel.fromJson(json['latest_weight'])
          : null,
      goal: json['goal'] != null ? GoalModel.fromJson(json['goal']) : null,
    );
  }
}

class WeightLogModel {
  final int id;
  final double weight;
  final double? bodyFat;
  final String date;

  WeightLogModel({
    required this.id,
    required this.weight,
    this.bodyFat,
    required this.date,
  });

  factory WeightLogModel.fromJson(Map<String, dynamic> json) {
    return WeightLogModel(
      id: json['id'],
      weight: (json['weight'] as num).toDouble(),
      bodyFat: json['body_fat'] != null
          ? (json['body_fat'] as num).toDouble()
          : null,
      date: json['date'],
    );
  }
}

class GoalModel {
  final int id;
  final String goalType;
  final String description;
  final double? targetValue;
  final double? currentValue;
  final String startDate;
  final String? deadline;
  final bool isActive;

  GoalModel({
    required this.id,
    required this.goalType,
    required this.description,
    this.targetValue,
    this.currentValue,
    required this.startDate,
    this.deadline,
    required this.isActive,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'],
      goalType: json['goal_type'],
      description: json['description'] ?? '',
      targetValue: json['target_value'] != null
          ? (json['target_value'] as num).toDouble()
          : null,
      currentValue: json['current_value'] != null
          ? (json['current_value'] as num).toDouble()
          : null,
      startDate: json['start_date'],
      deadline: json['deadline'],
      isActive: json['is_active'],
    );
  }
}

class CoachDashboardModel {
  final String name;
  final String speciality;
  final int yearsExperience;
  final List<TrainingGroupSummary> groups;

  CoachDashboardModel({
    required this.name,
    required this.speciality,
    required this.yearsExperience,
    required this.groups,
  });

  factory CoachDashboardModel.fromJson(Map<String, dynamic> json) {
    return CoachDashboardModel(
      name: json['name'],
      speciality: json['speciality'],
      yearsExperience: json['years_experience'],
      groups: (json['groups'] as List)
          .map((g) => TrainingGroupSummary.fromJson(g))
          .toList(),
    );
  }
}

class TrainingGroupSummary {
  final int id;
  final String name;

  TrainingGroupSummary({required this.id, required this.name});

  factory TrainingGroupSummary.fromJson(Map<String, dynamic> json) {
    return TrainingGroupSummary(id: json['id'], name: json['name']);
  }
}
