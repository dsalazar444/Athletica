import 'package:flutter/material.dart';
import '../../models/routine/routine_enums.dart';
import '../../models/routine/exercise_model.dart';
import '../../models/routine/selected_exercise.dart';
import '../../views/routine/exercise_selector_view.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../views/form_widgets/form_field_label_widget.dart';
import '../../views/form_widgets/styled_text_field_widget.dart';
import '../../views/form_widgets/syled_dropdown_widget.dart';

// ─────────────────────────────────────────────
//  NEW ROUTINE SCREEN
// ─────────────────────────────────────────────
class NewRoutineScreen extends StatefulWidget {
  const NewRoutineScreen({super.key});

  @override
  State<NewRoutineScreen> createState() => _NewRoutineScreenState();
}

class _NewRoutineScreenState extends State<NewRoutineScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  CategoryType _selectedCategory = CategoryType.hybrid;
  DifficultyLevel _selectedDifficulty = DifficultyLevel.advanced;

  final List<SelectedExercise> _selectedExercises = [
    SelectedExercise(
      exercise: ExerciseModel(
        id: 1,
        name: 'Press de Banca',
        description: 'Ejercicio de pecho con barra',
        muscles: [1,2],
      ),
      order: 1,
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openExerciseSelector() async {

    // Muestra a user modal para que selecciones ejercicio, puede ser exercise o null
    // await pausa la ejecución hasta que cierre modal
    final ExerciseModel? result = await showModalBottomSheet<ExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExerciseSelectorSheet(), 
    );

    // si hay result, verifica que no se quiera añadir un ejercicio que ya estaba, si no, lo agrega
    if (result != null) {
      setState(() {
        final alreadyAdded =
            _selectedExercises.any((e) => e.exercise.id == result.id);
        if (!alreadyAdded) { //Acá es donde se añaden SelectedExercise a var
          _selectedExercises.add(
            SelectedExercise(
              exercise: result,
              order: _selectedExercises.length + 1,
            ),
          );
        }
      });
    }
  }

  void _removeExercise(int exerciseId) {
    setState(() {
      _selectedExercises.removeWhere((e) => e.exercise.id == exerciseId);
      // Re-assign order numbers after removal
      for (int i = 0; i < _selectedExercises.length; i++) {
        _selectedExercises[i] = SelectedExercise(
          exercise: _selectedExercises[i].exercise,
          order: i + 1,
        );
      }
    });
  }

  // esto debe ir en view model
  void _handleSave() {
    // to do: implement save routine logic
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _RoutineScreenHeader(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BasicInfoCard(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      selectedCategory: _selectedCategory,
                      selectedDifficulty: _selectedDifficulty,
                      onCategoryChanged: (value) =>
                          setState(() => _selectedCategory = value),
                      onDifficultyChanged: (value) =>
                          setState(() => _selectedDifficulty = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ExerciseListSection(
                      exercises: _selectedExercises,
                      onAddExercise: _openExerciseSelector,
                      onRemoveExercise: _removeExercise,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            _RoutineActionButtons(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────
class _RoutineScreenHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _RoutineScreenHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Nueva Rutina', style: AppTextStyles.screenTitle),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BASIC INFO CARD
// ─────────────────────────────────────────────
class _BasicInfoCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final CategoryType selectedCategory;
  final DifficultyLevel selectedDifficulty;
  final ValueChanged<CategoryType> onCategoryChanged; //funcion que se llamará cuando usuario cambie categoria
  final ValueChanged<DifficultyLevel> onDifficultyChanged;

  const _BasicInfoCard({
    required this.titleController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Información Básica', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.lg),
          const FormFieldLabel(label: 'Título', isRequired: true),
          const SizedBox(height: AppSpacing.sm),
          StyledTextField(
            controller: titleController,
            hintText: 'Ej: Rutina de Fuerza Superior',
          ),
          const SizedBox(height: AppSpacing.md),
          const FormFieldLabel(label: 'Descripción (opcional)'),
          const SizedBox(height: AppSpacing.sm),
            StyledTextField(
            controller: descriptionController,
            hintText: 'Descripción de la rutina...',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormFieldLabel(label: 'Categoría'),
                    const SizedBox(height: AppSpacing.sm),
                    StyledDropdown<CategoryType>(
                      value: selectedCategory,
                      items: CategoryType.values,
                      labelBuilder: categoryTypeToString,
                      onChanged: onCategoryChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormFieldLabel(label: 'Dificultad'),
                    const SizedBox(height: AppSpacing.sm),
                    StyledDropdown<DifficultyLevel>(
                      value: selectedDifficulty,
                      items: DifficultyLevel.values,
                      labelBuilder: difficultyLevelToString,
                      onChanged: onDifficultyChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EXERCISE LIST SECTION
// ─────────────────────────────────────────────
class _ExerciseListSection extends StatelessWidget {
  final List<SelectedExercise> exercises;
  final VoidCallback onAddExercise;
  final ValueChanged<int> onRemoveExercise;

  const _ExerciseListSection({
    required this.exercises,
    required this.onAddExercise,
    required this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ejercicios (${exercises.length})',
              style: AppTextStyles.sectionTitle,
            ),
            GestureDetector(
              onTap: onAddExercise,
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: AppColors.primary),
                  SizedBox(width: AppSpacing.xs),
                  Text('Añadir ejercicio', style: AppTextStyles.addExerciseLink),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...exercises.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ExerciseListItem(
              selectedExercise: entry,
              onRemove: () => onRemoveExercise(entry.exercise.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseListItem extends StatelessWidget {
  final SelectedExercise selectedExercise;
  final VoidCallback onRemove;

  const _ExerciseListItem({
    required this.selectedExercise,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: AppColors.textHint, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${selectedExercise.order}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              selectedExercise.exercise.name,
              style: AppTextStyles.exerciseName,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_up,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.deleteRed,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ACTION BUTTONS
// ─────────────────────────────────────────────
class _RoutineActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _RoutineActionButtons({
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.button),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Cancelar', style: AppTextStyles.buttonSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.button),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Guardar Rutina', style: AppTextStyles.buttonPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
