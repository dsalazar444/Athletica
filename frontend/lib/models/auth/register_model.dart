enum UserRole { athlete, coach }
 
enum UserGoal { fuerza, resistencia, salud, estetica }
 
enum Experience { low, medium, high }
 
class RegisterModel {
  UserRole? role;
  String? username;
  String? email;
  String? password;
  String? password2;
  String? name;
  int? age;
  double? weight;
  double? height;
  String? gender;
  UserGoal? goal;
  Experience? experience;
 
  // Coach fields
  String? specialty;
  int? yearsExperience;
 
  RegisterModel({
    this.role,
    this.username,
    this.email,
    this.password,
    this.password2,
    this.name,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.goal,
    this.experience,
    this.specialty,
    this.yearsExperience,
  });
 
  Map<String, dynamic> toApiJson() {
    return {
      "username": username,
      "email": email,
      "password": password,
      "password2": password2,
      "role": role == UserRole.athlete ? "athlete" : "coach",
 
      if (role == UserRole.athlete)
        "athlete_profile": {
          "height": height != null ? height! / 100 : null,
          "age": age,
          "gender": gender,
          "activity_level": _mapExperience(),
          "goals": [
            {
              "goal_type": _mapGoal(),
              "description": null,
              "target_value": null,
            }
          ],
          "weight_logs": [
            {
              "weight": weight,
              "body_fat": null,
            }
          ]
        },
 
      if (role == UserRole.coach)
        "coach_profile": {
          "specialty": specialty,
          "years_experience": yearsExperience,
        },
    };
  }

  String _mapGoal() {
    switch (goal) {
      case UserGoal.fuerza:
        return "gain_muscle";
      case UserGoal.resistencia:
        return "endurance";
      case UserGoal.salud:
        return "health";
      case UserGoal.estetica:
        return "lose_weight";
      default:
        return "health";
    }
  }

  String _mapExperience() {
    switch (experience) {
      case Experience.low:
        return "low";
      case Experience.medium:
        return "medium";
      case Experience.high:
        return "high";
      default:
        return "medium";
    }
  }
}