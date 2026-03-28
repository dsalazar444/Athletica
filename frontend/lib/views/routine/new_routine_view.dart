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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fallo al guardar: $e')));
    }
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
                    // Formulario de datos básicos.
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
                    // Gestión de la lista de ejercicios.
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
            // Panel inferior con botones de acción.
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

/// Cabecera minimalista con botón de cierre.
class _RoutineScreenHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _RoutineScreenHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Nueva Rutina', style: AppTextStyles.screenTitle),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta que agrupa los campos principales del formulario (Título, Descripción, etc).
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
          const FormFieldLabel(label: 'Título de la rutina', isRequired: true),
          const SizedBox(height: AppSpacing.sm),
          StyledTextField(
            controller: titleController,
            hintText: 'Ej: Entrenamiento de Pierna A',
          ),
          const SizedBox(height: AppSpacing.md),
          const FormFieldLabel(label: 'Descripción (objetivos, notas)'),
          const SizedBox(height: AppSpacing.sm),
          StyledTextField(
            controller: descriptionController,
            hintText: 'Escribe una breve descripción...',
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

/// Sección que lista los ejercicios añadidos y ofrece el botón para agregar más.
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
            Expanded(
              child: Text(
                'Ejercicios seleccionados (${exercises.length})',
                style: AppTextStyles.sectionTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir', style: AppTextStyles.addExerciseLink),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (exercises.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'No has seleccionado ejercicios todavía.',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
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

/// Elemento individual de la lista de ejercicios seleccionados.
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
          // Burbuja con el número de orden.
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Text(
              '${selectedExercise.order}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              selectedExercise.exercise.name,
              style: AppTextStyles.exerciseName.copyWith(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.deleteRed,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botones inferiores para confirmar o descartar la creación de la rutina.
class _RoutineActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _RoutineActionButtons({required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
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
                  borderRadius: AppRadius.button,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Descartar',
                style: AppTextStyles.buttonSecondary,
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
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Crear Rutina',
                style: AppTextStyles.buttonPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
