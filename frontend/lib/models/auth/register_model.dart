// Roles disponibles en la aplicacion.
enum UserRole { athlete, coach }

// Tipos de meta que puede seleccionar un atleta durante el registro.
enum UserGoal { fuerza, resistencia, salud, estetica, mantener }

// Niveles de actividad disponibles para el atleta.
enum ActivityLevel { low, medium, high }

// Modelo que almacena temporalmente los datos del formulario de registro.
// Se construye paso a paso a traves del flujo de registro y se envia al backend al finalizar.
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
  ActivityLevel? activityLevel;

  // Campos exclusivos del perfil de coach.
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
    this.activityLevel,
    this.specialty,
    this.yearsExperience,
  });

  // Convierte el modelo al formato JSON que espera el backend.
  // Solo incluye el perfil correspondiente al rol del usuario.
  Map<String, dynamic> toApiJson() {
    return {
      'username': username,
      'email': email,
      'first_name': name,
      'password': password,
      'password2': password2,
      'role': role == UserRole.athlete ? 'athlete' : 'coach',

      // Solo se incluye athlete_profile si el usuario es atleta.
      if (role == UserRole.athlete)
        'athlete_profile': {
          // La altura se convierte de cm a metros para el backend.
          'height': height != null ? height! / 100 : null,
          'age': age,
          'gender': gender,
          'activity_level': _mapActivityLevel(),
          'goals': [
            {
              'goal_type': _mapGoal(),
              'description': null,
              'target_value': null,
            }
          ],
          'weight_logs': [
            {
              'weight': weight,
              'body_fat': null,
            }
          ]
        },

      // Solo se incluye coach_profile si el usuario es coach.
      if (role == UserRole.coach)
        'coach_profile': {
          'specialty': specialty,
          'years_experience': yearsExperience,
        },
    };
  }

  // Convierte el enum UserGoal al string que espera el backend.
  String _mapGoal() {
    switch (goal) {
      case UserGoal.fuerza:
        return 'gain_muscle';
      case UserGoal.resistencia:
        return 'endurance';
      case UserGoal.salud:
        return 'wellness';
      case UserGoal.estetica:
        return 'lose_weight';
      case UserGoal.mantener:
        return 'maintain';
      default:
        return 'wellness';
    }
  }

  // Convierte el enum ActivityLevel al string que espera el backend.
  String _mapActivityLevel() {
    switch (activityLevel) {
      case ActivityLevel.low:
        return 'low';
      case ActivityLevel.medium:
        return 'medium';
      case ActivityLevel.high:
        return 'high';
      default:
        return 'medium';
    }
  }
}