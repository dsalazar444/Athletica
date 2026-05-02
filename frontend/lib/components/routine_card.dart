import 'package:flutter/material.dart';
import '../models/routine/routine_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';

class RoutineCard extends StatelessWidget {
  final RoutineModel routine;
  final bool isCoach;
  final VoidCallback onTap;
  final VoidCallback? onAssign;
  final VoidCallback? onStartTraining;

  const RoutineCard({
    super.key,
    required this.routine,
    this.isCoach = false,
    required this.onTap,
    this.onAssign,
    this.onStartTraining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardLarge,
        boxShadow: AppColors.deepShadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardLarge,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildTopSection(), _buildFooter()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.title.toUpperCase(),
                  style: AppTextStyles.fitnessBold.copyWith(fontSize: 20),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildBadge(
                      routine.difficulty.toUpperCase(),
                      const Color(0xFFFFA500),
                    ),
                    _buildBadge(
                      "45 MIN",
                      AppColors.textSecondary.withValues(alpha: 0.1),
                      textColor: AppColors.textSecondary,
                    ),
                    if (isCoach && routine.assignedAthletesCount > 0)
                      _buildBadge(
                        "${routine.assignedAthletesCount} ATLETAS",
                        AppColors.primary.withValues(alpha: 0.15),
                        textColor: AppColors.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 'Iniciar entrenamiento' button
          if (onStartTraining != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: onStartTraining,
                icon: const Icon(Icons.play_arrow_rounded, size: 14),
                label: Text(
                  "Iniciar",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.buttonPrimary.copyWith(
                    fontSize: 12,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  "${routine.exercises.length} EJERCICIOS",
                  style: AppTextStyles.fitnessCaption.copyWith(fontSize: 9),
                ),
                const SizedBox(width: 8),
                Text(
                  "|",
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    children: [
                      Text(
                        "DETALLES",
                        style: AppTextStyles.fitnessCaption.copyWith(
                          color: AppColors.primary,
                          fontSize: 9,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 8,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCoach && onAssign != null)
            ElevatedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.person_add_alt_rounded, size: 12),
              label: const Text(
                "ASIGNAR",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
