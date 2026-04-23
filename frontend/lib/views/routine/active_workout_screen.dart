import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../repositories/routine/workout_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../models/routine/workout_set_ui_model.dart';
import '../../models/routine/active_exercise_model.dart';
import '../../models/routine/routine__exercise_model.dart';
import '../../view_models/routine/active_workout_view_model.dart';

// WorkoutSetEntry -> WorkoutSetUiModel
// ACtiveWorkout -> stays

// ─────────────────────────────────────────────
//  LOCAL STYLE VARIABLES
//  Declarados globalmente porque se usan en varios
//  widgets distintos — no son inline.
// ─────────────────────────────────────────────
const TextStyle _timerStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: AppColors.primary,
);

const TextStyle _subtitleStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w500,
  color: AppColors.textSecondary,
);

const TextStyle _exerciseMetaStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  color: AppColors.textSecondary,
);

const TextStyle _lastRecordDateStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: Color(0xFFD94E28),
);

const TextStyle _lastRecordValueStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: AppColors.textPrimary,
);

const TextStyle _setNumberStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: AppColors.textSecondary,
);

const TextStyle _setFieldLabelStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
  letterSpacing: 0.3,
);

const TextStyle _setFieldValueStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

// ─────────────────────────────────────────────
//  SAMPLE DATA
// ─────────────────────────────────────────────
// List<ActiveExerciseModel> buildSampleExercises() => [
//       ActiveExerciseModel(
//         id: '1',
//         name: 'Press de Banca',
//         targetSets: 4,
//         targetRepsRange: '8-10',
//         restSeconds: 120,
//         initials: 'PB',
//         lastRecordDate: '2026-04-18',
//         lastRecordSummary: '80 kg × 10 reps',
//         sets: [
//           WorkoutSetUiModel(reps: 5,  weightKg: 5),
//           WorkoutSetUiModel(reps: 10, weightKg: 80),
//           WorkoutSetUiModel(reps: 10, weightKg: 80),
//           WorkoutSetUiModel(reps: 10, weightKg: 80),
//         ],
//       ),
//       ActiveExerciseModel(
//         id: '2',
//         name: 'Press Militar',
//         targetSets: 3,
//         targetRepsRange: '10-12',
//         restSeconds: 90,
//         initials: 'PM',
//         lastRecordDate: '2026-04-18',
//         lastRecordSummary: '50 kg × 10 reps',
//         sets: [
//           WorkoutSetEntry(reps: 10, weightKg: 50),
//           WorkoutSetEntry(reps: 10, weightKg: 50),
//           WorkoutSetEntry(reps: 10, weightKg: 50),
//         ],
//       ),
//       ActiveExerciseModel(
//         id: '3',
//         name: 'Fondos',
//         targetSets: 3,
//         targetRepsRange: '12-15',
//         restSeconds: 60,
//         initials: 'FD',
//         sets: [
//           WorkoutSetEntry(reps: 12, weightKg: 0),
//           WorkoutSetEntry(reps: 12, weightKg: 0),
//           WorkoutSetEntry(reps: 12, weightKg: 0),
//         ],
//       ),
//       ActiveExerciseModel(
//         id: '4',
//         name: 'Curl Bíceps',
//         targetSets: 3,
//         targetRepsRange: '10-12',
//         restSeconds: 60,
//         initials: 'CB',
//         sets: [
//           WorkoutSetEntry(reps: 10, weightKg: 20),
//           WorkoutSetEntry(reps: 10, weightKg: 20),
//           WorkoutSetEntry(reps: 10, weightKg: 20),
//         ],
//       ),
//     ];

// ─────────────────────────────────────────────
//  ACTIVE WORKOUT SCREEN
// ─────────────────────────────────────────────
class ActiveWorkoutScreen extends StatefulWidget {
  final int routineId;
  final String routineName;
  final List<RoutineExerciseModel> exercises;

  const ActiveWorkoutScreen({
    super.key,
    required this.routineId,
    required this.routineName,
    required this.exercises,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  late final List<List<WorkoutSetUiModel>> _allSets;
  int _elapsedSeconds = 0;
  late final Timer _timer;
  late final ActiveWorkoutViewModel _viewModel;
  late final List<ActiveExerciseModel> _activeExercises;

  @override
  void initState() {
    super.initState();

    _viewModel = ActiveWorkoutViewModel(
      workoutRepository: WorkoutRepository(baseUrl: ApiConfig.baseUrl),
    );
    _activeExercises = _viewModel.toActiveExercises(widget.exercises);

    _allSets = _activeExercises
        .map((e) => e.sets.map((s) => s.copyWith()).toList())
        .toList();

    _initializeSession();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _elapsedSeconds++),
    );
  }

  Future<void> _initializeSession() async {
    try {
      await _viewModel.initSession(routineId: widget.routineId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar la sesión de entrenamiento.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  ActiveExerciseModel get _currentExercise =>
      _activeExercises[_currentExerciseIndex];

  List<WorkoutSetUiModel> get _currentSets => _allSets[_currentExerciseIndex];

  bool get _isLastExercise =>
      _currentExerciseIndex == _activeExercises.length - 1;

  Future<void> _goToNextExercise() async {
    if (_viewModel.isSaving) return;

    if (_isLastExercise) {
      try {
        await _viewModel.finishWorkout(
          routineId: widget.routineId,
          allSets: _allSets,
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudieron guardar los datos del entrenamiento.',
            ),
          ),
        );
      }
    } else {
      setState(() => _currentExerciseIndex++);
    }
  }

  void _toggleSetCompleted(int setIndex) {
    setState(() {
      final set = _currentSets[setIndex];
      _currentSets[setIndex] = set.copyWith(isCompleted: !set.isCompleted);
    });
  }

  void _updateSetReps(int setIndex, int delta) {
    setState(() {
      final current = _currentSets[setIndex].reps;
      final updatedBase = _currentSets[setIndex].base.copyWith(
        reps: (current + delta).clamp(0, 999),
      );
      _currentSets[setIndex] = _currentSets[setIndex].copyWith(
        base: updatedBase,
      );
    });
  }

  void _updateSetWeight(int setIndex, double delta) {
    setState(() {
      final current = _currentSets[setIndex].weightKg;
      final updatedBase = _currentSets[setIndex].base.copyWith(
        weight: (current + delta).clamp(0, 9999),
      );
      _currentSets[setIndex] = _currentSets[setIndex].copyWith(
        base: updatedBase,
      );
    });
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _activeExercises.length;
    final progress = (_currentExerciseIndex + 1) / total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _WorkoutTopBar(
              routineName: widget.routineName,
              currentIndex: _currentExerciseIndex + 1,
              totalCount: total,
              elapsedLabel: _formatElapsed(_elapsedSeconds),
              progress: progress,
              onCancel: () => Navigator.of(context).pop(),
            ),
            _ExerciseTabRow(
              exercises: _activeExercises,
              currentIndex: _currentExerciseIndex,
              onTabSelected: (i) => setState(() => _currentExerciseIndex = i),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _ExerciseInfoCard(exercise: _currentExercise),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Registrar Series',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._currentSets.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _SetRow(
                          setNumber: entry.key + 1,
                          setEntry: entry.value,
                          onToggleComplete: () =>
                              _toggleSetCompleted(entry.key),
                          onRepsChanged: (d) => _updateSetReps(entry.key, d),
                          onWeightChanged: (d) =>
                              _updateSetWeight(entry.key, d),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            _NextExerciseButton(
              label: _isLastExercise ? 'Finalizar' : 'Siguiente',
              isLoading: _viewModel.isSaving,
              onPressed: _viewModel.isSaving ? null : _goToNextExercise,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────
class _WorkoutTopBar extends StatelessWidget {
  final String routineName;
  final int currentIndex;
  final int totalCount;
  final String elapsedLabel;
  final double progress;
  final VoidCallback onCancel;

  const _WorkoutTopBar({
    required this.routineName,
    required this.currentIndex,
    required this.totalCount,
    required this.elapsedLabel,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onCancel,
                child: Row(
                  children: [
                    const Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    Text('Cancelar', style: _subtitleStyle),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(elapsedLabel, style: _timerStyle),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(routineName, style: AppTextStyles.screenTitle),
          const SizedBox(height: AppSpacing.xs),
          Text('Ejercicio $currentIndex de $totalCount', style: _subtitleStyle),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.chip,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EXERCISE TAB ROW
// ─────────────────────────────────────────────
class _ExerciseTabRow extends StatelessWidget {
  final List<ActiveExerciseModel> exercises;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _ExerciseTabRow({
    required this.exercises,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.md),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: exercises.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, index) {
            final isActive = index == currentIndex;
            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  borderRadius: AppRadius.chip,
                ),
                child: Text(
                  exercises[index].name,
                  style: AppTextStyles.chipLabel.copyWith(
                    color: isActive ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EXERCISE INFO CARD
// ─────────────────────────────────────────────
class _ExerciseInfoCard extends StatelessWidget {
  final ActiveExerciseModel exercise;

  const _ExerciseInfoCard({required this.exercise});

  String get _restLabel {
    final mins = exercise.restSeconds ~/ 60;
    final secs = exercise.restSeconds % 60;
    return secs == 0 ? 'Descanso: ${mins}min' : 'Descanso: ${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ExerciseAvatar(initials: exercise.initials),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: AppTextStyles.exerciseName),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${exercise.sets.length} series  •  ${ActiveWorkoutViewModel.defaultReps} reps base  •  $_restLabel',
                      style: _exerciseMetaStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EE),
              borderRadius: AppRadius.input,
              border: Border.all(color: const Color(0xFFFF8C5A), width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sin registro previo (valor por defecto)',
                  style: _lastRecordDateStyle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${ActiveWorkoutViewModel.defaultWeight.toStringAsFixed(0)} kg × ${ActiveWorkoutViewModel.defaultReps} reps',
                  style: _lastRecordValueStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseAvatar extends StatelessWidget {
  final String initials;

  const _ExerciseAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.tagBackground,
        borderRadius: AppRadius.card,
      ),
      child: Center(
        child: Text(
          initials,
          // inline: solo se usa aquí
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SET ROW
// ─────────────────────────────────────────────
class _SetRow extends StatelessWidget {
  final int setNumber;
  final WorkoutSetUiModel setEntry;
  final VoidCallback onToggleComplete;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;

  const _SetRow({
    required this.setNumber,
    required this.setEntry,
    required this.onToggleComplete,
    required this.onRepsChanged,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: setEntry.isCompleted
            ? AppColors.cardSelectedBg
            : AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: setEntry.isCompleted
              ? AppColors.borderSelected
              : AppColors.border,
          width: setEntry.isCompleted ? 1.5 : 1,
        ),
        boxShadow: AppColors.softShadow,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$setNumber', style: _setNumberStyle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SetStepperField(
              label: 'Repeticiones',
              value: setEntry.reps.toString(),
              onDecrement: () => onRepsChanged(-1),
              onIncrement: () => onRepsChanged(1),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SetStepperField(
              label: 'Peso (kg)',
              value: setEntry.weightKg % 1 == 0
                  ? setEntry.weightKg.toInt().toString()
                  : setEntry.weightKg.toStringAsFixed(1),
              onDecrement: () => onWeightChanged(-2.5),
              onIncrement: () => onWeightChanged(2.5),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onToggleComplete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: setEntry.isCompleted
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 18,
                color: setEntry.isCompleted
                    ? AppColors.white
                    : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SET STEPPER FIELD
// ─────────────────────────────────────────────
class _SetStepperField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _SetStepperField({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _setFieldLabelStyle),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.input,
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(child: Text(value, style: _setFieldValueStyle)),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepperArrow(
                    icon: Icons.keyboard_arrow_up,
                    onTap: onIncrement,
                  ),
                  _StepperArrow(
                    icon: Icons.keyboard_arrow_down,
                    onTap: onDecrement,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        // inline: solo se usa aquí el tamaño y color del ícono
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NEXT / FINISH BUTTON
// ─────────────────────────────────────────────
class _NextExerciseButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _NextExerciseButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(label, style: AppTextStyles.buttonPrimary),
        ),
      ),
    );
  }
}
