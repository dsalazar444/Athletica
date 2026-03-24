import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../main_screen.dart';
import 'register_flow_screen.dart';

// Pantalla de login — permite al usuario autenticarse con username y contrasena.
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

  void validate() {
    setState(() {
      usernameError = username.text.isEmpty ? 'El username es requerido' : null;
      passwordError = password.text.isEmpty ? 'La contrasena es requerida' : null;
      isValid = usernameError == null && passwordError == null;
    });
  }

  // Envia las credenciales al backend y guarda los tokens si el login es exitoso.
  Future<void> login() async {
  validate();
  if (!isValid) return;

  setState(() {
    isLoading = true;
    generalError = null;
  });

  try {
    print('Intentando login con: ${username.text}');
    final response = await ApiClient.dio.post('auth/login/', data: {
      'username': username.text,
      'password': password.text,
    });
    print('Login response: ${response.data}');

    await TokenStorage.saveTokens(
      access: response.data['access'],
      refresh: response.data['refresh'],
      athleteId: response.data['athlete_id'],
      name: response.data['first_name'],
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  } catch (e) {
    print('Login error: $e');
    setState(() {
      generalError = 'Usuario o contrasena incorrectos';
    });
  } finally {
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [

          // Cabecera
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            color: AppColors.primary,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Athletica',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Bienvenido de vuelta',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Formulario
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inicia sesion',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),

                  // Mensaje de error general (credenciales incorrectas)
                  if (generalError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        generalError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),

                  TextField(
                    controller: username,
                    onChanged: (_) => validate(),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: usernameError,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: password,
                    obscureText: true,
                    onChanged: (_) => validate(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: passwordError,
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Boton de login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Iniciar sesion'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Enlace para ir al registro
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterFlowScreen()),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'No tienes cuenta? ',
                          style: TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: 'Registrate',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}