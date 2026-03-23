import 'package:flutter/material.dart';
import 'package:frontend/models/routine/routine_enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../models/routine/exercise_model.dart';
import '../../view_models/routine/exercise_selector_view_model.dart';
import '../../repositories/routine/exercise_repository.dart';

/// Hoja modal (BottomSheet) para la selección de ejercicios desde el catálogo global.
/// Incluye búsqueda por texto y filtros por grupo muscular.
class ExerciseSelectorSheet extends StatefulWidget {
  const ExerciseSelectorSheet({super.key});

  @override
  State<ExerciseSelectorSheet> createState() => _ExerciseSelectorSheetState();
}

class _ExerciseSelectorSheetState extends State<ExerciseSelectorSheet> {
  // Controlador para el campo de búsqueda de texto.
  final TextEditingController _searchController = TextEditingController();
  
  // Categoría de filtro seleccionada (por defecto 'Todos', aunque proviene de un Enum).
  String _selectedCategory = 'Todos'; 
  
  // Texto actual de la consulta de búsqueda.
  String _searchQuery = ''; 
  
  late ExerciseViewModel viewModel;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel con su repositorio correspondiente.
    viewModel = ExerciseViewModel(ExerciseRepository());
    _loadExercises();
  }

  /// Filtra los ejercicios basándose en el query y la categoría seleccionada.
  List<ExerciseModel> get _filteredExercises => viewModel.filteredExercises(_searchQuery, _selectedCategory);

  /// Carga el catálogo completo de ejercicios desde la API.
  Future<void> _loadExercises() async {
    await viewModel.loadExercises();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Estado de carga inicial.
    if (isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _SheetDragHandle(), // Indicador visual de que el modal es deslizable.
          _SelectorHeader(
            onClose: () => Navigator.of(context).pop(),
          ),
          _SearchBar(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          _CategoryFilterRow(
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredExercises.length} ejercicios encontrados',
                        style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _ExerciseResultList(
                    exercises: _filteredExercises,
                    onExerciseSelected: (exercise) => Navigator.of(context).pop(exercise),
                  ),
                ),
              ],
            ),
          ),
          // Botón para crear ejercicios personalizados (aún no implementado).
          _CreateExerciseButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad de creación personalizada próximamente.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Pequeña barra superior decorativa para el modal.
class _SheetDragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Título y botón de cierre del selector.
class _SelectorHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _SelectorHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Añadir Ejercicio', style: AppTextStyles.screenTitle),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 24),
          ),
        ],
      ),
    );
  }
}

/// Barra de entrada de texto para filtrar ejercicios por nombre.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: 'Ej: Sentadillas, Press...',
          hintStyle: AppTextStyles.hintText,
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: AppRadius.input,
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      ),
    );
  }
}

/// Fila horizontal de chips para filtrar por grupo muscular.
class _CategoryFilterRow extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryFilterRow({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: MuscleGroup.values.length + 1, // +1 para la opción "Todos"
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final String category;
          if (index == 0) {
            category = 'Todos';
          } else {
            category = muscleGroupToString(MuscleGroup.values[index - 1]);
          }
          final isSelected = category == selectedCategory;
          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: AppRadius.chip,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                category,
                style: AppTextStyles.chipLabel.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Lista scrolleable que muestra los resultados de la búsqueda/filtro.
class _ExerciseResultList extends StatelessWidget {
  final List<ExerciseModel> exercises;
  final ValueChanged<ExerciseModel> onExerciseSelected;

  const _ExerciseResultList({
    required this.exercises,
    required this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const Center(
        child: Text('No se encontraron ejercicios.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) => _ExerciseResultCard(
        exercise: exercises[index],
        onAdd: () => onExerciseSelected(exercises[index]),
      ),
    );
  }
}

/// Tarjeta individual para cada ejercicio en el listado de búsqueda.
class _ExerciseResultCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onAdd;

  const _ExerciseResultCard({required this.exercise, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _ExerciseAvatar(initials: exercise.name.substring(0, 1), imageUrl: exercise.imageUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: AppTextStyles.exerciseName),
                const SizedBox(height: 4),
                _CategoryTag(label: exercise.primaryMuscleName),
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
          ),
        ],
      ),
    );
  }
}

/// Avatar circular o imagen del ejercicio para la tarjeta de resultados.
class _ExerciseAvatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;

  const _ExerciseAvatar({required this.initials, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.tagBackground,
        borderRadius: AppRadius.card,
      ),
      child: Center(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: AppRadius.card,
                child: Image.network(
                  imageUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Text(
                    initials,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              )
            : Text(initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ),
    );
  }
}

/// Etiqueta estilizada para el grupo muscular en la tarjeta.
class _CategoryTag extends StatelessWidget {
  final String label;
  const _CategoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: const BoxDecoration(
        color: AppColors.tagBackground,
        borderRadius: AppRadius.chip,
      ),
      child: Text(label, style: AppTextStyles.tagLabel),
    );
  }
}

/// Botón persistente en la parte inferior para habilitar la creación de ejercicios personalizados.
class _CreateExerciseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateExerciseButton({required this.onPressed});

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
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, color: AppColors.primary),
          label: const Text('¿No encuentras tu ejercicio? Créalo aquí', 
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
