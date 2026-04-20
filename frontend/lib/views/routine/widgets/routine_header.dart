import 'package:flutter/material.dart';
import '../../../../models/routine/routine_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_text_styles.dart';

class RoutineHeader extends StatelessWidget {
  final RoutineModel routine;

  const RoutineHeader({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.cardLarge,
        boxShadow: AppColors.deepShadow,
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTag(
                routine.category,
                Colors.white.withValues(alpha: 0.25),
                Colors.white,
              ),
              const SizedBox(width: 8),
              _buildTag(
                routine.difficulty,
                Colors.white.withValues(alpha: 0.25),
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            routine.title.toUpperCase(),
            style: AppTextStyles.fitnessDisplay.copyWith(color: Colors.white),
          ),
          if (routine.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              routine.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (routine.creatorName != null &&
              routine.creatorName!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Asignado por: ${routine.creatorName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.fitnessCaption.copyWith(
          color: textColor,
          fontSize: 10,
        ),
      ),
    );
  }
}
