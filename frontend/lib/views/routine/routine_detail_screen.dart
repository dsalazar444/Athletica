import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine/routine_model.dart';
import '../../models/routine/routine__exercise_model.dart';
import '../../core/config/api_config.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../view_models/routine/routine_detail_view_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import 'exercise_detail_screen.dart';

/// Pantalla detallada de una rutina específica.
/// Muestra la información de la rutina y la lista de ejercicios que la componen.
/// Utiliza [RoutineDetailViewModel] para gestionar el estado y las acciones en la rutina.
class RoutineDetailScreen extends StatelessWidget {
  final RoutineModel routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    final repository = RoutineRepository(baseUrl: ApiConfig.baseUrl);

    return ChangeNotifierProvider(
      create: (_) => RoutineDetailViewModel(
        routineRepository: repository,
        routine: routine,
      ),
      child: Consumer<RoutineDetailViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text(
                'Detalle de Rutina',
                style: AppTextStyles.screenTitle,
              ),
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
              actions: [
                if (viewModel.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: viewModel.refreshRoutine,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoutineInfo(viewModel.routine),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Ejercicios (${viewModel.routine.exercises.length})',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildExercisesList(context, viewModel),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye la tarjeta superior con la información destacada de la rutina.
  Widget _buildRoutineInfo(RoutineModel routine) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.textPrimary, Color(0xFF333333)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiquetas de categoría y dificultad.
          Row(
            children: [
              _buildTag(
                routine.category,
                Colors.white.withValues(alpha: 0.2),
                Colors.white,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildTag(
                routine.difficulty,
                Colors.white.withValues(alpha: 0.2),
                Colors.white,
              ),
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
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye una etiqueta pequeña con fondo semitransparente.
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

  /// Genera la lista de ejercicios como tarjetas interactivas.
  Widget _buildExercisesList(
    BuildContext context,
    RoutineDetailViewModel viewModel,
  ) {
    if (viewModel.routine.exercises.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          'Esta rutina no tiene ejercicios asignados.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: viewModel.routine.exercises.length,
      itemBuilder: (context, index) {
        final routineExercise = viewModel.routine.exercises[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navega al detalle histórico del ejercicio.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(
                    routineExercise: routineExercise,
                    routineId: viewModel.routine.id!,
                  ),
                ),
              ).then((_) => viewModel.refreshRoutine());
            },
            borderRadius: AppRadius.card,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.card,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador del orden del ejercicio en la rutina.
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
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
                          style: AppTextStyles.exerciseName.copyWith(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              routineExercise.exercise.primaryMuscleName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botón para eliminar el ejercicio de esta rutina.
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 22,
                    ),
                    onPressed: () {
                      _showDeleteConfirmation(
                        context,
                        viewModel,
                        routineExercise,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Muestra un diálogo de confirmación antes de eliminar el ejercicio de la rutina.
  void _showDeleteConfirmation(
    BuildContext context,
    RoutineDetailViewModel viewModel,
    RoutineExerciseModel re,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar Ejercicio'),
        content: Text(
          '¿Estás seguro de que quieres remover "${re.exercise.name}" de esta rutina?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              viewModel.removeExercise(re.exercise.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
