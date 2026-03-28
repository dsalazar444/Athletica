import '../../models/auth/register_model.dart';
import '../../repositories/auth/auth_repository.dart';

// ViewModel para el flujo de registro.
// Mantiene el estado del formulario y coordina la navegacion entre pasos.
class RegisterViewModel {
  // Modelo que acumula los datos del usuario a lo largo del flujo.
  final RegisterModel data = RegisterModel();

  final AuthRepository _authRepository = AuthRepository();

  // Paso actual del flujo de registro (0 a 5).
  int step = 0;

  // Indica si hay una peticion en curso para mostrar un indicador de carga.
  bool isLoading = false;

  // Mensaje de error para mostrar al usuario si el registro falla.
  String? errorMessage;

  // Avanza al siguiente paso del flujo.
  // El coach salta directamente al paso final despues del paso 2
  // ya que no tiene los pasos de metas ni experiencia.
  void next() {
    if (data.role == UserRole.coach && step == 2) {
      step = 5;
    } else {
      step++;
    }
  }

  // Retrocede al paso anterior.
  void back() {
    if (step > 0) step--;
  }

  // Envia los datos acumulados al backend para crear la cuenta.
  // Retorna true si el registro fue exitoso, false si hubo un error.
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
      // Siempre desactiva el estado de carga al terminar, sin importar el resultado.
      isLoading = false;
    }
  }
}
