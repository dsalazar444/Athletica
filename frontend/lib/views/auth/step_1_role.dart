import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("¿Cuál es tu rol?", style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            "Selecciona cómo usarás la aplicación para personalizar tu experiencia.",
            style: AppTextStyles.sectionSubtitle,
          ),
          const SizedBox(height: 32),
          _card(
            title: "Soy Atleta",
            subtitle: "Quiero entrenar, registrar mi progreso y ver rutinas.",
            value: UserRole.athlete,
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 16),
          _card(
            title: "Soy Entrenador",
            subtitle:
                "Quiero gestionar grupos, crear rutinas y seguir atletas.",
            value: UserRole.coach,
            icon: Icons.psychology_outlined,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedRole == null
                  ? null
                  : () => widget.onNext(selectedRole!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              child: Text("Continuar", style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required UserRole value,
    required IconData icon,
  }) {
    final isSelected = selectedRole == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : AppColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: AppRadius.cardLarge,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected ? AppColors.deepShadow : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? AppColors.softShadow : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyText1.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
