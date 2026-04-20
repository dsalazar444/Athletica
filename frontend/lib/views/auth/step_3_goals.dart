import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../models/auth/register_model.dart';


class Step3Goals extends StatefulWidget {
  final Function(UserGoal) onNext;

  const Step3Goals({super.key, required this.onNext});

  @override
  State<Step3Goals> createState() => _Step3GoalsState();
}

class _Step3GoalsState extends State<Step3Goals> {
  UserGoal? selectedGoal;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuál es tu objetivo?',
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona tu meta principal para que el coach pueda guiarte mejor.',
            style: AppTextStyles.sectionSubtitle,
          ),
          const SizedBox(height: 32),
          _card('Ganar Fuerza', UserGoal.fuerza, Icons.bolt_rounded),
          const SizedBox(height: 12),
          _card('Resistencia Cardíaca', UserGoal.resistencia, Icons.favorite_rounded),
          const SizedBox(height: 12),
          _card('Acondicionamiento y Salud', UserGoal.salud, Icons.health_and_safety_rounded),
          const SizedBox(height: 12),
          _card('Estética y Tonificación', UserGoal.estetica, Icons.visibility_rounded),
          const SizedBox(height: 12),
          _card('Mantener Peso Actual', UserGoal.mantener, Icons.balance_rounded),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: selectedGoal == null
                  ? null
                  : () => widget.onNext(selectedGoal!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
              ),
              child: const Text('Continuar', style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, UserGoal value, IconData icon) {
    final isSelected = selectedGoal == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGoal = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? AppColors.deepShadow : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected ? AppColors.softShadow : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textHint,
                size: 24,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.goalLabel.copyWith(
                  fontSize: 16,
                  color: isSelected ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26),
          ],
        ),
      ),
    );
  }
}


