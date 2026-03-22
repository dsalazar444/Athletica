import '../../models/auth/register_model.dart';

class RegisterViewModel {
  final RegisterModel data = RegisterModel();
  int step = 0;

  void next() {
    // Coach solo tiene: step 0 (rol), step 1 (account), step 2 (coach) → final
    if (data.role == UserRole.coach && step == 2) {
      step = 5; // salta directo al final
    } else {
      step++;
    }
  }

  void back() {
    if (step > 0) step--;
  }
}