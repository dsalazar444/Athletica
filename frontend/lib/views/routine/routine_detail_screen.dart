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
import '../../core/token_storage.dart';
import 'exercise_detail_screen.dart';
import 'widgets/routine_header.dart';
import 'widgets/exercise_list_item.dart';
import 'widgets/add_exercise_sheet.dart';

class RoutineDetailScreen extends StatelessWidget {
  final RoutineModel routine;
  final bool isOwner;

  const RoutineDetailScreen({
    super.key,
    required this.routine,
    this.isOwner = true,
  });

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
                  )
                else if (isOwner)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    onPressed: () =>
                        _showDeleteRoutineConfirmation(context, viewModel),
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
                    RoutineHeader(routine: viewModel.routine),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildCoachSection(viewModel),
                    _buildExercisesSection(context, viewModel),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoachSection(RoutineDetailViewModel viewModel) {
    return FutureBuilder<String?>(
      future: TokenStorage.getUserRole(),
      builder: (context, snapshot) {
        final isCoach = snapshot.data == 'coach';
        if (isCoach && viewModel.routine.assignedAthletesInfo.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                "ATLETAS ACTIVOS (${viewModel.routine.assignedAthletesInfo.length})",
              ),
              const SizedBox(height: AppSpacing.md),
              _buildActiveAthletesList(viewModel.routine.assignedAthletesInfo),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildExercisesSection(
    BuildContext context,
    RoutineDetailViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(
              "EJERCICIOS (${viewModel.routine.exercises.length})",
            ),
            if (isOwner)
              TextButton.icon(
                onPressed: () => _showAddExerciseSheet(context, viewModel),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text("Añadir"),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildExercisesList(context, viewModel),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.fitnessBold.copyWith(
          color: AppColors.textPrimary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildExercisesList(
    BuildContext context,
    RoutineDetailViewModel viewModel,
  ) {
    if (viewModel.routine.exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: AppColors.textHint.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta rutina no tiene ejercicios asignados.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: viewModel.routine.exercises.length,
      itemBuilder: (context, index) {
        final routineExercise = viewModel.routine.exercises[index];
        return ExerciseListItem(
          routineExercise: routineExercise,
          isOwner: isOwner,
          onTap: () {
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
          onDelete: () =>
              _showDeleteConfirmation(context, viewModel, routineExercise),
        );
      },
    );
  }

  void _showDeleteRoutineConfirmation(
    BuildContext context,
    RoutineDetailViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Borrar Rutina", style: AppTextStyles.fitnessBold),
        content: const Text(
          "¿Estás seguro de que quieres borrar esta rutina? Esta acción no se puede deshacer.",
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await viewModel.routineRepository.deleteRoutine(
                  viewModel.routine.id!,
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Rutina eliminada.")),
                  );
                }
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Borrar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseSheet(
    BuildContext context,
    RoutineDetailViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExerciseSheet(
        routineId: viewModel.routine.id!,
        currentExerciseCount: viewModel.routine.exercises.length,
        repository: viewModel.routineRepository,
        onAdded: () => viewModel.refreshRoutine(),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    RoutineDetailViewModel viewModel,
    RoutineExerciseModel re,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        title: const Text(
          'Quitar Ejercicio',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '¿Estás seguro de que quieres remover "${re.exercise.name}" de esta rutina?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              viewModel.removeExercise(re.exercise.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'REMOVER',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAthletesList(List<Map<String, dynamic>> athletes) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: athletes.length,
        itemBuilder: (context, index) {
          final athlete = athletes[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  athlete['first_name']?[0] ?? 'A',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              label: Text(athlete['first_name'] ?? 'Atleta'),
              backgroundColor: AppColors.surface,
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          );
        },
      ),
    );
  }
}

class RoutineDetailScreenFromId extends StatefulWidget {
  final int routineId;
  const RoutineDetailScreenFromId({super.key, required this.routineId});

  @override
  State<RoutineDetailScreenFromId> createState() =>
      _RoutineDetailScreenFromIdState();
}

class _RoutineDetailScreenFromIdState extends State<RoutineDetailScreenFromId> {
  RoutineModel? _routine;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    try {
      final repository = RoutineRepository(baseUrl: ApiConfig.baseUrl);
      final routine = await repository.fetchRoutineDetail(widget.routineId);
      if (mounted) {
        setState(() {
          _routine = routine;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "No se pudo cargar la rutina.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null || _routine == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? "Error desconocido")),
      );
    }

    return RoutineDetailScreen(routine: _routine!);
  }
}
