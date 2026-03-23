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

class RegisterFlowScreen extends StatefulWidget {
  const RegisterFlowScreen({super.key});

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {

  final vm = RegisterViewModel();

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

          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Athletica",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Configura tu perfil",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // PROGRESS BAR
                Row(
                  children: List.generate(6, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index <= vm.step
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // CONTENIDO
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
              child:

              // STEP 0 → ROL
              vm.step == 0
                  ? Step1Role(
                      onNext: (role) {
                        vm.data.role = role;
                        nextStep();
                      },
                    )

              // STEP 1 → ACCOUNT
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

              // STEP 2 → PERSONAL / COACH
              : vm.step == 2
                  ? (vm.data.role == UserRole.coach
                      ? Step2Coach(
                          onNext: (specialty, years) async {
                            vm.data.specialty = specialty;
                            vm.data.yearsExperience = int.parse(years);

                            final success = await vm.register();
                            if (success) {
                              nextStep();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(vm.errorMessage ?? 'Error desconocido')),
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

              // STEP 3 → GOALS
              : vm.step == 3
                  ? Step3Goals(
                      onNext: (goal) {
                        vm.data.goal = goal;
                        nextStep();
                      },
                    )

              // STEP 4 → EXPERIENCE
              : vm.step == 4
                  ? Step4Experience(
                      onNext: (exp) async {
                        vm.data.experience = exp;

                        final success = await vm.register();
                        if (success) {
                          nextStep();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(vm.errorMessage ?? 'Error desconocido')),
                          );
                        }   // 👈 cierre del if/else, sin nextStep() suelto
                      },
                    )

              // FINAL
              : const Center(
                  child: Text("Registro completado"),
                ),
            ),
          ),
        ],
      ),
    );
  }
}