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
      passwordError = password.text.isEmpty
          ? 'La contraseña es requerida'
          : null;
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

  void _forgotPassword() {
    final emailController = TextEditingController();
    bool isRequesting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'RECUPERAR CONTRASEÑA',
              style: AppTextStyles.fitnessBold.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingresa tu email registrado. Te enviaremos un código de recuperación.',
                  style: AppTextStyles.bodyText1.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: isRequesting
                    ? null
                    : () async {
                        if (emailController.text.isEmpty) return;
                        setDialogState(() => isRequesting = true);
                        try {
                          await ApiClient.dio.post(
                            'auth/password-reset/',
                            data: {'email': emailController.text},
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showResetConfirmDialog(emailController.text);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error al solicitar recuperación',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => isRequesting = false);
                          }
                        }
                      },
                child: isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'ENVIAR CÓDIGO',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmDialog(String email) {
    final tokenController = TextEditingController();
    final passwordController = TextEditingController();
    final uidController = TextEditingController();
    bool isResetting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'ESTABLECER NUEVA CLAVE',
              style: AppTextStyles.fitnessBold.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Revisa tu bandeja de entrada. Ingresa el UID y Token recibidos.',
                    style: AppTextStyles.bodyText1.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSimpleInput(uidController, 'UID', Icons.fingerprint),
                  const SizedBox(height: 12),
                  _buildSimpleInput(tokenController, 'Token', Icons.vpn_key),
                  const SizedBox(height: 12),
                  _buildSimpleInput(
                    passwordController,
                    'Nueva Contraseña',
                    Icons.lock_outline,
                    isPassword: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isResetting
                    ? null
                    : () async {
                        if (tokenController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          return;
                        }
                        setDialogState(() => isResetting = true);
                        try {
                          await ApiClient.dio.post(
                            'auth/password-reset-confirm/',
                            data: {
                              'uid': uidController.text,
                              'token': tokenController.text,
                              'password': passwordController.text,
                            },
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '¡Contraseña actualizada! Ya puedes iniciar sesión.',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error: Token inválido o expirado',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setDialogState(() => isResetting = false);
                          }
                        }
                      },
                child: isResetting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'ACTUALIZAR',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimpleInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: AppColors.primary.withValues(alpha: 0.05),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Solid Background
          Positioned.fill(child: Container(color: AppColors.primary)),

          Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATHLETICA',
                      style: AppTextStyles.fitnessHero.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '⚡ TU PROGRESO COMIENZA AQUÍ',
                        style: AppTextStyles.fitnessCaption.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(48),
                    ),
                    boxShadow: AppColors.deepShadow,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BIENVENIDO',
                          style: AppTextStyles.fitnessDisplay.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
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
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textHint,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                              shadowColor: AppColors.primary.withValues(
                                alpha: 0.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.button,
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Entrar a mi cuenta',
                                    style: AppTextStyles.buttonPrimary,
                                  ),
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
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              generalError!,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
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
            style: AppTextStyles.bodyText1.copyWith(
              color: AppColors.textSecondary,
            ),
            children: const [
              TextSpan(
                text: 'Regístrate aquí',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
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
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
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
