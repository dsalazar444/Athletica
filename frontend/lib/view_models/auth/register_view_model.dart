import '../../models/auth/register_model.dart';
import '../../repositories/auth/auth_repository.dart';

class RegisterViewModel {
  final RegisterModel data = RegisterModel();
  final AuthRepository _authRepository = AuthRepository();

  int step = 0;
  bool isLoading = false;
  String? errorMessage;

  void next() {
    // Coach solo tiene: step 0 (rol), step 1 (account), step 2 (coach) → final
    if (data.role == UserRole.coach && step == 2) {
      step = 5;
    } else {
      step++;
    }
  }

  void back() {
    if (step > 0) step--;
  }

  Future<bool> register() async {
    isLoading = true;
    errorMessage = null;

    try {
      await _authRepository.register(data);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }
}