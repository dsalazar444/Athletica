import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Solid Background
          Positioned.fill(
            child: Container(
              color: AppColors.primary,
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
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primary.withValues(alpha: 0.7),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.5, 0.7],
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 80, 24, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ATHLETICA', style: AppTextStyles.fitnessHero.copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CONFIGURA TU PERFIL',
                        style: AppTextStyles.fitnessCaption.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Progress Bar
                    Row(
                      children: List.generate(6, (index) {
                        final isActive = vm.step >= index;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: isActive 
                                ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10)] 
                                : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
                    boxShadow: AppColors.deepShadow,
                  ),
                  child: _buildCurrentStep(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCurrentStep() {
    if (vm.step == 0) {
      return Step1Role(
        onNext: (role) {
          vm.data.role = role;
          nextStep();
        },
      );
    } else if (vm.step == 1) {
      return Step2Account(
        onNext: (username, email, password, password2) {
          vm.data.username = username;
          vm.data.email = email;
          vm.data.password = password;
          vm.data.password2 = password2;
          nextStep();
        },
      );
    } else if (vm.step == 2) {
      if (vm.data.role == UserRole.coach) {
        return Step2Coach(
          onNext: (specialty, years) async {
            vm.data.specialty = specialty;
            vm.data.yearsExperience = int.parse(years);
            final success = await vm.register();
            if (success) {
              nextStep();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(vm.errorMessage ?? 'Error desconocido')),
              );
            }
          },
        );
      } else {
        return Step2Personal(
          onNext: (name, age, weight, height, gender) {
            vm.data.name = name;
            vm.data.age = int.parse(age);
            vm.data.weight = double.parse(weight);
            vm.data.height = double.parse(height);
            vm.data.gender = gender;
            nextStep();
          },
        );
      }
    } else if (vm.step == 3) {
      return Step3Goals(
        onNext: (goal) {
          vm.data.goal = goal;
          nextStep();
        },
      );
    } else if (vm.step == 4) {
      return Step4Experience(
        onNext: (exp) async {
          vm.data.activityLevel = exp;
          final success = await vm.register();
          if (success) {
            nextStep();
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(vm.errorMessage ?? 'Error desconocido')),
            );
          }
        },
      );
    } else {
      return _buildSuccessStep();
    }
  }

  Widget _buildSuccessStep() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 80),
            ),
            const SizedBox(height: 32),
            Text('¡Registro completado!', style: AppTextStyles.h2),
            const SizedBox(height: 12),
            Text(
              'Tu cuenta ha sido creada con éxito.\nYa puedes empezar a entrenar.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                ),
                child: const Text('Ir al Inicio', style: AppTextStyles.buttonPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
