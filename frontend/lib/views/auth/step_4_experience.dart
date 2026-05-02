import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../models/auth/register_model.dart';

class Step4Experience extends StatefulWidget {
  final Future<void> Function(ActivityLevel) onNext;
  const Step4Experience({super.key, required this.onNext});

  @override
  State<Step4Experience> createState() => _Step4ExperienceState();
}

class _Step4ExperienceState extends State<Step4Experience> {
  ActivityLevel? selectedLevel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nivel de experiencia", style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(
            "Selecciona tu nivel actual para ajustar la intensidad de tus rutinas.",
            style: AppTextStyles.sectionSubtitle,
          ),
          const SizedBox(height: 32),
          _card(
            "Principiante",
            ActivityLevel.low,
            "Estoy empezando o tengo poca experiencia.",
          ),
          const SizedBox(height: 12),
          _card(
            "Intermedio",
            ActivityLevel.medium,
            "Entreno regularmente y conozco las técnicas.",
          ),
          const SizedBox(height: 12),
          _card(
            "Avanzado",
            ActivityLevel.high,
            "Tengo años entrenando y domino movimientos complejos.",
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: selectedLevel == null
                  ? null
                  : () async => await widget.onNext(selectedLevel!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              child: const Text(
                "Finalizar Registro",
                style: AppTextStyles.buttonPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, ActivityLevel value, String description) {
    final isSelected = selectedLevel == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = value;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTextStyles.bodyText1.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 30,
              ),
          ],
        ),
      ),
    );
  }
}
