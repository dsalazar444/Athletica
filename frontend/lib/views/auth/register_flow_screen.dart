import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../view_models/auth/register_view_model.dart';
import '../../models/auth/register_model.dart';

import 'step_1_role.dart';
import 'step_2_account.dart';
import 'step_2_personal.dart';
import 'step_2_coach.dart';
import 'step_3_goals.dart';
import 'step_4_experience.dart';

// Pantalla principal del flujo de registro.
// Coordina los pasos del formulario y muestra el contenido correspondiente a cada paso.
class RegisterFlowScreen extends StatefulWidget {
  const RegisterFlowScreen({super.key});

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {
  final vm = RegisterViewModel();

  // Avanza al siguiente paso y reconstruye la pantalla.
  void nextStep() {
    setState(() {
      vm.next();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Cabecera con el nombre de la app, subtitulo y barra de progreso.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Athletica',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Configura tu perfil',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Barra de progreso — cada segmento representa un paso del flujo.
                // Los pasos completados se muestran en blanco, los pendientes en blanco transparente.
                Row(
                  children: List.generate(6, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: (vm.step >= index)
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Area de contenido — muestra el widget correspondiente al paso actual.
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child:
                  // Paso 0 — seleccion de rol (atleta o coach).
                  vm.step == 0
                  ? Step1Role(
                      onNext: (role) {
                        vm.data.role = role;
                        nextStep();
                      },
                    )
                  // Paso 1 — datos de la cuenta (usuario, email, contrasena).
                  : vm.step == 1
                  ? Step2Account(
                      onNext: (username, email, password, password2) {
                        vm.data.username = username;
                        vm.data.email = email;
                        vm.data.password = password;
                        vm.data.password2 = password2;
                        nextStep();
                      },
                    )
                  // Paso 2 — datos personales del atleta o datos del coach.
                  // Muestra un formulario diferente segun el rol seleccionado.
                  : vm.step == 2
                  ? (vm.data.role == UserRole.coach
                        ? Step2Coach(
                            onNext: (specialty, years) async {
                              vm.data.specialty = specialty;
                              vm.data.yearsExperience = int.parse(years);

                              final messenger = ScaffoldMessenger.of(context);
                              // El coach envia el registro en este paso — no tiene pasos adicionales.
                              final success = await vm.register();
                              if (success) {
                                nextStep();
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      vm.errorMessage ?? 'Error desconocido',
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        : Step2Personal(
                            onNext: (name, age, weight, height, gender) {
                              vm.data.name = name;
                              vm.data.age = int.parse(age);
                              vm.data.weight = double.parse(weight);
                              vm.data.height = double.parse(height);
                              vm.data.gender = gender;
                              nextStep();
                            },
                          ))
                  // Paso 3 — seleccion de meta de entrenamiento (solo atleta).
                  : vm.step == 3
                  ? Step3Goals(
                      onNext: (goal) {
                        vm.data.goal = goal;
                        nextStep();
                      },
                    )
                  // Paso 4 — nivel de experiencia (solo atleta).
                  // Al completar este paso se envia el registro al backend.
                  : vm.step == 4
                  ? Step4Experience(
                      onNext: (exp) async {
                        vm.data.activityLevel = exp;

                        final messenger = ScaffoldMessenger.of(context);
                        final success = await vm.register();
                        if (success) {
                          nextStep();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                vm.errorMessage ?? 'Error desconocido',
                              ),
                            ),
                          );
                        }
                      },
                    )
                  // Paso final — confirmacion de registro completado.
                  // Incluye un boton temporal para verificar que el token funciona correctamente.
                  : Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.primary,
                              size: 80,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              '¡Registro completado!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tu cuenta ha sido creada con éxito. Ya puedes empezar a entrenar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Redirige al inicio (MainScreen)
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/',
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Ir al Inicio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
