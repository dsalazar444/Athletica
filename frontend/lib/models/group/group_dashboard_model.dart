import 'package:flutter/foundation.dart';

class GroupDashboardModel {
  final int groupId;
  final String groupName;
  final int totalMembers;
  final GroupMetrics groupMetrics;
  final List<AthleteDashboardEntry> athletes;

  GroupDashboardModel({
    required this.groupId,
    required this.groupName,
    required this.totalMembers,
    required this.groupMetrics,
    required this.athletes,
  });

  factory GroupDashboardModel.fromJson(Map<String, dynamic> json) {
    debugPrint('fromJson athletes raw: ${(json['athletes'] as List).length}');
    return GroupDashboardModel(
      groupId: json['group_id'],
      groupName: json['group_name'],
      totalMembers: json['total_members'],
      groupMetrics: GroupMetrics.fromJson(json['group_metrics']),
      athletes: (json['athletes'] as List)
          .map((a) => AthleteDashboardEntry.fromJson(a))
          .toList(),
    );
  }
}

class AthleteDashboardEntry {
  final int id;
  final String username;
  final String firstName;
  final String email;
  final int age;
  final String gender;
  final String activityLevel;
  final AthleteWeightEntry? latestWeight;
  final String weightTrend;
  final AthleteGoalEntry? activeGoal;

  AthleteDashboardEntry({
    required this.id,
    required this.username,
    required this.firstName,
    required this.email,
    required this.age,
    required this.gender,
    required this.activityLevel,
    this.latestWeight,
    required this.weightTrend,
    this.activeGoal,
  });

  String get displayName => firstName.isNotEmpty ? firstName : username;

  factory AthleteDashboardEntry.fromJson(Map<String, dynamic> json) {
    return AthleteDashboardEntry(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'] ?? '',
      email: json['email'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      activityLevel: json['activity_level'] ?? '',
      latestWeight: json['latest_weight'] != null
          ? AthleteWeightEntry.fromJson(json['latest_weight'])
          : null,
      weightTrend: json['weight_trend'] ?? 'no_data',
      activeGoal: json['active_goal'] != null
          ? AthleteGoalEntry.fromJson(json['active_goal'])
          : null,
    );
  }
}

class AthleteWeightEntry {
  final double weight;
  final String date;
  final double? bodyFat;

  AthleteWeightEntry({required this.weight, required this.date, this.bodyFat});

  factory AthleteWeightEntry.fromJson(Map<String, dynamic> json) {
    return AthleteWeightEntry(
      weight: (json['weight'] as num).toDouble(),
      date: json['date'].toString(),
      bodyFat: json['body_fat'] != null
          ? (json['body_fat'] as num).toDouble()
          : null,
    );
  }
}

class AthleteGoalEntry {
  final int id;
  final String goalType;
  final double? targetValue;
  final double? currentValue;
  final String? deadline;

  AthleteGoalEntry({
    required this.id,
    required this.goalType,
    this.targetValue,
    this.currentValue,
    this.deadline,
  });

  factory AthleteGoalEntry.fromJson(Map<String, dynamic> json) {
    return AthleteGoalEntry(
      id: json['id'],
      goalType: json['goal_type'],
      targetValue: json['target_value'] != null
          ? (json['target_value'] as num).toDouble()
          : null,
      currentValue: json['current_value'] != null
          ? (json['current_value'] as num).toDouble()
          : null,
      deadline: json['deadline'],
    );
  }
}

class GroupMetrics {
  final int totalWithGoal;
  final int totalWithRoutine;
  final int totalWithWeightData;
  final double? avgWeight;

  GroupMetrics({
    required this.totalWithGoal,
    required this.totalWithRoutine,
    required this.totalWithWeightData,
    this.avgWeight,
  });

  factory GroupMetrics.fromJson(Map<String, dynamic> json) {
    return GroupMetrics(
      totalWithGoal: json['total_with_goal'],
      totalWithRoutine: json['total_with_routine'],
      totalWithWeightData: json['total_with_weight_data'],
      avgWeight: json['avg_weight'] != null
          ? (json['avg_weight'] as num).toDouble()
          : null,
    );
  }
}
