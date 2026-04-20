import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../main_screen.dart';
import 'register_flow_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();

  String? usernameError;
  String? passwordError;
  String? generalError;

  bool isLoading = false;
  bool isValid = false;
  bool _obscurePassword = true;

  void validate() {
    setState(() {
      usernameError = username.text.isEmpty ? 'El username es requerido' : null;
      passwordError = password.text.isEmpty ? 'La contraseña es requerida' : null;
      isValid = usernameError == null && passwordError == null;
    });
  }

  Future<void> login() async {
    validate();
    if (!isValid) return;

    setState(() {
      isLoading = true;
      generalError = null;
    });

    try {
      final response = await ApiClient.dio.post(
        'auth/login/',
        data: {'username': username.text, 'password': password.text},
      );

      await TokenStorage.saveTokens(
        access: response.data['access'],
        refresh: response.data['refresh'],
        athleteId: response.data['athlete_id'],
        userId: response.data['user_id'],
        name: response.data['first_name'],
        role: response.data['role'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          generalError = 'Usuario o contraseña incorrectos';
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Solid Background
          Positioned.fill(
            child: Container(
              color: AppColors.primary, // Naranja
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.4, 0.65],
                ),
              ),
            ),
          ),
          Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ATHLETICA', style: AppTextStyles.fitnessHero.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TU PROGRESO COMIENZA AQUÍ',
                        style: AppTextStyles.fitnessCaption.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
                    boxShadow: AppColors.deepShadow,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BIENVENIDO', style: AppTextStyles.fitnessDisplay.copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          'Inicia sesión para continuar tu entrenamiento.',
                          style: AppTextStyles.sectionSubtitle,
                        ),
                        const SizedBox(height: 40),
                        if (generalError != null) _buildErrorMessage(),
                        _buildInput(
                          label: 'Usuario o Email',
                          controller: username,
                          errorText: usernameError,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 24),
                        _buildInput(
                          label: 'Contraseña',
                          controller: password,
                          errorText: passwordError,
                          icon: Icons.lock_outline_rounded,
                          isPassword: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.textHint,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: AppColors.primary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Entrar a mi cuenta', style: AppTextStyles.buttonPrimary),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildRegisterLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.input,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              generalError!,
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterFlowScreen()),
          );
        },
        child: Text.rich(
          TextSpan(
            text: '¿No tienes cuenta? ',
            style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
            children: const [
              TextSpan(
                text: 'Regístrate aquí',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    String? errorText,
    required IconData icon,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(label, style: AppTextStyles.inputLabel),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          onChanged: (_) => validate(),
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textHint, size: 22),
            suffixIcon: suffixIcon,
            errorText: errorText,
            filled: true,
            fillColor: AppColors.background.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}



