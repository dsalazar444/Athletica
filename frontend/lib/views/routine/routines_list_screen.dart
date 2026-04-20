import 'package:flutter/material.dart';
import '../../models/routine/routine_model.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/routines_list_view_model.dart';
import '../../core/config/api_config.dart';
import 'new_routine_view.dart';
import 'routine_detail_screen.dart';
import 'workout_history_screen.dart';
import '../../core/token_storage.dart';
import '../../components/routine_card.dart';
import 'widgets/assignment_bottom_sheet.dart';

class RoutinesListScreen extends StatefulWidget {
  const RoutinesListScreen({super.key});

  @override
  State<RoutinesListScreen> createState() => RoutinesListScreenState();
}

class RoutinesListScreenState extends State<RoutinesListScreen> {
  late final RoutinesListViewModel _viewModel;
  String? _userRole;
  bool _showPersonalRoutines = false;

  @override
  void initState() {
    super.initState();
    _viewModel = RoutinesListViewModel(
      routineRepository: RoutineRepository(baseUrl: ApiConfig.baseUrl),
    );
    _viewModel.addListener(_onViewModelChange);
    refresh();
  }

  Future<void> refresh() async {
    final role = await TokenStorage.getUserRole();
    final userId = await TokenStorage.getUserId();
    if (mounted) setState(() => _userRole = role);
    _viewModel.loadRoutines(athleteId: role == 'athlete' ? userId : null);
  }

  void _onViewModelChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  Future<void> _navigateAndRefresh() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NewRoutineScreen()));
    final athleteId = await TokenStorage.getAthleteId();
    _viewModel.loadRoutines(
      athleteId: _userRole == 'athlete' ? athleteId : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: (_userRole == 'athlete' && !_showPersonalRoutines)
          ? null
          : _buildFAB(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton.extended(
        heroTag: 'routines_fab',
        onPressed: _navigateAndRefresh,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva Rutina',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MIS RUTINAS",
                  style: AppTextStyles.fitnessDisplay.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "GESTIONA TUS ENTRENAMIENTOS",
                  style: AppTextStyles.fitnessCaption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildActionCircle(Icons.history_rounded, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildContent() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_viewModel.errorMessage != null) return _buildErrorState();
    if (_userRole == 'athlete' && !_showPersonalRoutines) {
      return _buildAthleteHub();
    }
    return _buildRoutineList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: refresh, child: const Text("REINTENTAR")),
          ],
        ),
      ),
    );
  }

  Widget _buildAthleteHub() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildPlanCard(),
        const SizedBox(height: 24),
        _buildPersonalRoutinesEntry(),
        const SizedBox(height: 32),
        if (_viewModel.routines.isNotEmpty) _buildRecentRoutinesSection(),
      ],
    );
  }

  Widget _buildPlanCard() {
    return GestureDetector(
      onTap: () {
        if (_viewModel.activeRoutine != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RoutineDetailScreen(
                routine: _viewModel.activeRoutine!,
                isOwner: false,
              ),
            ),
          ).then((_) => _viewModel.loadRoutines());
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Sin plan asignado.")));
        }
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: AppRadius.cardLarge,
          boxShadow: AppColors.deepShadow,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.star_rounded, color: Colors.white, size: 32),
            const Spacer(),
            const Text(
              "MI PLAN COACH",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _viewModel.activeRoutine != null
                  ? "Plan: ${_viewModel.activeRoutine!.title}"
                  : "Sin plan activo",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRoutinesEntry() {
    return GestureDetector(
      onTap: () => setState(() => _showPersonalRoutines = true),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardLarge,
          boxShadow: AppColors.softShadow,
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=2070&auto=format&fit=crop',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardLarge,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                Icons.fitness_center_rounded,
                color: Colors.white,
                size: 32,
              ),
              const Spacer(),
              const Text(
                "MIS RUTINAS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Crea y gestiona tus propios planes",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRoutinesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "RECIENTES",
              style: AppTextStyles.fitnessBold.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showPersonalRoutines = true),
              child: const Text("VER TODAS"),
            ),
          ],
        ),
        ..._viewModel.routines
            .take(2)
            .map(
              (r) => RoutineCard(
                routine: r,
                isCoach: false,
                onTap: () => _openDetail(r),
              ),
            ),
      ],
    );
  }

  Widget _buildRoutineList() {
    if (_viewModel.routines.isEmpty) return _buildEmptyState();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      children: [
        if (_userRole == 'athlete' && _showPersonalRoutines)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _showPersonalRoutines = false),
              ),
              Text("MIS RUTINAS", style: AppTextStyles.inputLabel),
            ],
          ),
        const SizedBox(height: 12),
        ..._viewModel.routines.map(
          (r) => RoutineCard(
            routine: r,
            isCoach: _userRole == 'coach',
            onTap: () => _openDetail(r),
            onAssign: () => _openAssignDialog(r),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 60,
            color: AppColors.textHint.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _userRole == 'coach'
                ? "CREA UNA RUTINA PARA ASIGNARLA"
                : "NO TIENES RUTINAS CREADAS",
            style: AppTextStyles.fitnessBold.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openDetail(RoutineModel routine) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RoutineDetailScreen(routine: routine),
          ),
        )
        .then((deleted) {
          if (deleted == true) refresh();
        });
  }

  void _openAssignDialog(RoutineModel routine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignmentBottomSheet(
        routine: routine,
        onSuccess: () => _viewModel.loadRoutines(),
      ),
    );
  }
}
