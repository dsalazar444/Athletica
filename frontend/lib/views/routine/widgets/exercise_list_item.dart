import 'package:flutter/material.dart';
import '../../../../models/routine/routine__exercise_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_text_styles.dart';

class ExerciseListItem extends StatelessWidget {
  final RoutineExerciseModel routineExercise;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ExerciseListItem({
    super.key,
    required this.routineExercise,
    this.isOwner = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
              boxShadow: AppColors.softShadow,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildOrderBadge(),
                const SizedBox(width: 20),
                Expanded(child: _buildInfo()),
                if (isOwner && onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textHint,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderBadge() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          '${routineExercise.order}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          routineExercise.exercise.name,
          style: AppTextStyles.exerciseName.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                routineExercise.exercise.primaryMuscleName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                const Text(
                  'Repeticiones',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
