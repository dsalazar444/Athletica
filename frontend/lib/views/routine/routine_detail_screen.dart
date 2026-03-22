import 'package:flutter/material.dart';
import '../../models/routine/routine_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';

class RoutineDetailScreen extends StatelessWidget {
  final RoutineModel routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle de Rutina', style: AppTextStyles.screenTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoutineInfo(),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Ejercicios (${routine.exercises.length})',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildExercisesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineInfo() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.textPrimary, const Color(0xFF333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTag(routine.category, Colors.white.withOpacity(0.2), Colors.white),
              const SizedBox(width: AppSpacing.sm),
              _buildTag(routine.difficulty, Colors.white.withOpacity(0.2), Colors.white),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            routine.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.surface,
              letterSpacing: -0.5,
            ),
          ),
          if (routine.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              routine.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.tagLabel.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildExercisesList() {
    if (routine.exercises.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          'Esta rutina no tiene ejercicios.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: routine.exercises.length,
      itemBuilder: (context, index) {
        final routineExercise = routine.exercises[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${routineExercise.order}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routineExercise.exercise.name,
                      style: AppTextStyles.exerciseName.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          routineExercise.exercise.primaryMuscleName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (routineExercise.exercise.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        routineExercise.exercise.description,
                        style: AppTextStyles.exerciseSubtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Icon(Icons.chevron_right, color: AppColors.textHint),
              ),
            ],
          ),
        );
      },
    );
  }
}
