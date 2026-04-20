import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

class Step2Account extends StatefulWidget {
  final Function(String, String, String, String) onNext;

  const Step2Account({super.key, required this.onNext});

  @override
  State<Step2Account> createState() => _Step2AccountState();
}

class _Step2AccountState extends State<Step2Account> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final password2 = TextEditingController();

  // Mensajes de error por campo — null significa que no hay error.
  String? usernameError;
  String? emailError;
  String? passwordError;
  String? password2Error;

  bool isValid = false;

  // Valida cada campo y actualiza los mensajes de error.
  void validate() {
    setState(() {
      usernameError = _validateUsername(username.text);
      emailError = _validateEmail(email.text);
      passwordError = _validatePassword(password.text);
      password2Error = _validatePassword2(password2.text);

      isValid =
          usernameError == null &&
          emailError == null &&
          passwordError == null &&
          password2Error == null;
    });
  }

  // Sin espacios, solo letras, numeros y guiones bajos, minimo 3 caracteres.
  String? _validateUsername(String value) {
    if (value.isEmpty) return 'El username es requerido';
    if (value.length < 3) return 'El username debe tener al menos 3 caracteres';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo se permiten letras, numeros y guion bajo';
    }
    return null;
  }

  // Formato de email valido.
  String? _validateEmail(String value) {
    if (value.isEmpty) return 'El email es requerido';
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(value)) {
      return 'Ingresa un email valido';
    }
    return null;
  }

  // Minimo 8 caracteres, al menos una letra y un numero.
  String? _validatePassword(String value) {
    if (value.isEmpty) return 'La contrasena es requerida';
    if (value.length < 8) {
      return 'La contrasena debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un numero';
    }
    return null;
  }

  // Debe coincidir con la contrasena ingresada.
  String? _validatePassword2(String value) {
    if (value.isEmpty) return 'Confirma tu contrasena';
    if (value != password.text) return 'Las contrasenas no coinciden';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crea tu cuenta', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Ingresa tus datos de acceso para comenzar.',
            style: AppTextStyles.sectionSubtitle,
          ),
          const SizedBox(height: 32),
          _input(
            'Nombre de usuario',
            username,
            usernameError,
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 20),
          _input(
            'Correo electrónico',
            email,
            emailError,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 20),
          _input(
            'Contraseña',
            password,
            passwordError,
            isPassword: true,
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 20),
          _input(
            'Confirmar contraseña',
            password2,
            password2Error,
            isPassword: true,
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: isValid
                  ? () => widget.onNext(
                      username.text,
                      email.text,
                      password.text,
                      password2.text,
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              child: Text('Continuar', style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController c,
    String? errorText, {
    bool isPassword = false,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          obscureText: isPassword,
          onChanged: (_) => validate(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textHint, size: 22),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
