class ProfileSettingsModel {
  final String name;
  final int? age;
  final double? weight;
  final double? height;
  final String? trainingGoal;
  final String role;

  ProfileSettingsModel({
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.trainingGoal,
    required this.role,
  });

  factory ProfileSettingsModel.fromJson(Map<String, dynamic> json) {
    return ProfileSettingsModel(
      name: (json['name'] as String?) ?? 'Usuario',
      age: json['age'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      trainingGoal: json['training_goal'] as String?,
      role: (json['role'] as String?) ?? 'athlete',
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      if (age != null) 'age': age,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (trainingGoal != null) 'training_goal': trainingGoal,
    };
  }
}
