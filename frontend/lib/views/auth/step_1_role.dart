import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/auth/register_model.dart';

class Step1Role extends StatefulWidget {
  final Function(UserRole) onNext;

  const Step1Role({super.key, required this.onNext});

  @override
  State<Step1Role> createState() => _Step1RoleState();
}

class _Step1RoleState extends State<Step1Role> {

  UserRole? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "¿Cuál es tu rol?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          "Selecciona cómo usarás la aplicación",
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 20),

        // USUARIO
        _card(
          title: "Atleta",
          subtitle: "Entrena y registra tu progreso",
          value: UserRole.athlete,
        ),

        const SizedBox(height: 15),

        // ENTRENADOR
        _card(
          title: "Entrenador",
          subtitle: "Gestiona grupos de atletas",
          value: UserRole.coach,
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedRole == null
                ? null
                : () => widget.onNext(selectedRole!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Continuar",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required UserRole value, //
  }) {
    final isSelected = selectedRole == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                      )),
                ],
              ),
            ),

            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}