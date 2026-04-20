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
import '../../view_models/routine/new_routine_view_model.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../core/config/api_config.dart';

/// Pantalla para crear una nueva rutina de entrenamiento.
/// Permite definir nombre, descripción, categoría, dificultad y seleccionar una lista de ejercicios.
class NewRoutineScreen extends StatefulWidget {
  const NewRoutineScreen({super.key});

  @override
  State<NewRoutineScreen> createState() => _NewRoutineScreenState();
}

class _NewRoutineScreenState extends State<NewRoutineScreen> {
  // Controladores para los campos de texto del formulario.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Valores por defecto para los selectores de categoría y dificultad.
  CategoryType _selectedCategory = CategoryType.hybrid;
  DifficultyLevel _selectedDifficulty = DifficultyLevel.advanced;

  /// Lista local de ejercicios seleccionados por el usuario para la nueva rutina.
  final List<SelectedExercise> _selectedExercises = [];

  late final RoutineViewModel _routineViewModel;

  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel con el repositorio configurado.
    _routineViewModel = RoutineViewModel(
      routineRepository: RoutineRepository(baseUrl: ApiConfig.baseUrl),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Abre un modal para buscar y elegir un ejercicio del catálogo global.
  Future<void> _openExerciseSelector() async {
    final ExerciseModel? result = await showModalBottomSheet<ExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExerciseSelectorSheet(),
    );

    if (result != null) {
      setState(() {
        // Evitamos añadir el mismo ejercicio más de una vez.
        final alreadyAdded = _selectedExercises.any(
          (e) => e.exercise.id == result.id,
        );
        if (!alreadyAdded) {
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

  /// Remueve un ejercicio de la lista temporal y reajusta el orden de los restantes.
  void _removeExercise(int exerciseId) {
    setState(() {
      _selectedExercises.removeWhere((e) => e.exercise.id == exerciseId);
      for (int i = 0; i < _selectedExercises.length; i++) {
        _selectedExercises[i] = SelectedExercise(
          exercise: _selectedExercises[i].exercise,
          order: i + 1,
        );
      }
    });
  }

  /// Valida y envía los datos al ViewModel para persistir la rutina en el backend.
  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El título es obligatorio')));
      return;
    }

    try {
      await _routineViewModel.saveRoutine(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory.name,
        difficulty: _selectedDifficulty.name,
        selectedExercises: _selectedExercises,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Rutina creada con éxito!')),
      );

      // Pequeña pausa para que el usuario vea el mensaje de éxito antes de cerrar.
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fallo al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Information Section
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
                  const SizedBox(height: AppSpacing.xl),
                  // Exercise Section
                  _ExerciseListSection(
                    exercises: _selectedExercises,
                    onAddExercise: _openExerciseSelector,
                    onRemoveExercise: _removeExercise,
                  ),
                  const SizedBox(height: 20),
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
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: AppColors.mediumShadow,
      ),
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
              ),
              Text(
                'ATHLETICA',
                style: AppTextStyles.fitnessCaption.copyWith(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 40), // Balance
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'DISEÑA TU'.toUpperCase(),
            style: AppTextStyles.fitnessCaption.copyWith(color: Colors.white.withValues(alpha: 0.8), letterSpacing: 2),
          ),
          Text(
            'PROPIA RUTINA',
            style: AppTextStyles.fitnessDisplay.copyWith(color: Colors.white, fontSize: 32),
          ),
        ],
      ),
    );
  }
}


/// Tarjeta Bento-Style para información básica.
class _BasicInfoCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final CategoryType selectedCategory;
  final DifficultyLevel selectedDifficulty;
  final ValueChanged<CategoryType> onCategoryChanged;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Text('DEFINICIÓN', style: AppTextStyles.fitnessBold.copyWith(fontSize: 20)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormFieldLabel(label: 'Título de la rutina', isRequired: true),
              const SizedBox(height: AppSpacing.sm),
              StyledTextField(
                controller: titleController,
                hintText: 'Ej: Entrenamiento de Pierna A',
              ),
              const SizedBox(height: AppSpacing.xl),
              const FormFieldLabel(label: 'Descripción'),
              const SizedBox(height: AppSpacing.sm),
              StyledTextField(
                controller: descriptionController,
                hintText: 'Objetivos o notas...',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xl),
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
        ),
      ],
    );
  }
}

/// Sección de ejercicios con estética refinada.
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Text('EJERCICIOS', style: AppTextStyles.fitnessBold.copyWith(fontSize: 20)),
              ],
            ),
            GestureDetector(
              onTap: onAddExercise,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    const Text('Añadir', style: AppTextStyles.addExerciseLink),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (exercises.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: AppRadius.cardLarge,
              border: Border.all(color: AppColors.border, style: BorderStyle.none),
            ),
            child: Column(
              children: [
                Icon(Icons.layers_clear_rounded, color: AppColors.textHint.withValues(alpha: 0.5), size: 48),
                const SizedBox(height: 12),
                Text(
                  'Tu lista de ejercicios está vacía',
                  style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final entry = exercises[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ExerciseListItem(
                  selectedExercise: entry,
                  onRemove: () => onRemoveExercise(entry.exercise.id),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Item de ejercicio modernizado.
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
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 40,
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Center(
                child: Text(
                  '#${selectedExercise.order}',
                  style: AppTextStyles.fitnessBold.copyWith(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedExercise.exercise.name.toUpperCase(),
                      style: AppTextStyles.fitnessBold.copyWith(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      selectedExercise.exercise.primaryMuscleName,
                      style: AppTextStyles.cardSubtitle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.deleteRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Botones de acción finales con estilo premium.
class _RoutineActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _RoutineActionButtons({required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onCancel,
              child: Text(
                'DESCARTAR',
                style: AppTextStyles.fitnessCaption.copyWith(color: AppColors.textHint),
              ),
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
                elevation: 10,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text('CREAR RUTINA', style: AppTextStyles.buttonPrimary.copyWith(letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
