import 'package:flutter/material.dart';
import 'package:frontend/models/routine/routine_enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../models/routine/exercise_model.dart';
import '../../view_models/routine/exercise_selector_view_model.dart';
import '../../repositories/routine/exercise_repository.dart';

class ExerciseSelectorSheet extends StatefulWidget {
  const ExerciseSelectorSheet({super.key}); // constructor de este widget

  //Indicamos a flutter que cuando use este widget, debe crear un objeto tipo _Ex..., que es donde se maneja lógica que cambia estado
  @override
  State<ExerciseSelectorSheet> createState() => _ExerciseSelectorSheetState();
}

class _ExerciseSelectorSheetState extends State<ExerciseSelectorSheet> {
  // controlador que permite saber que escribe el usuario en barra de busqueda
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todos'; // guarda categoria seleccionada por user
  String _searchQuery =
      ''; // Guarda lo que usuario escribe en barra de busqueda
  late ExerciseViewModel viewModel; // objeto con el que traeremos datos
  bool isLoading = true;

  // funcion "main" de vista
  @override
  void initState() {
    super
        .initState(); // llamamos funcion original de flutter para saber que todo esta bien

    //inicializamos var con objeto -> los atributos de la clase son los parametros que se deben pasar a objeto
    viewModel = ExerciseViewModel(ExerciseRepository());

    _loadExercises();
  }

  // usamos viewModel para manejar logica de filtrado
  List<ExerciseModel> get _filteredExercises =>
      viewModel.filteredExercises(_searchQuery);

  // Carga ejercicios desde view model, Future es para funciones que tardan (tiene async)
  Future<void> _loadExercises() async {
    await viewModel
        .loadExercises(); // espera hasta que se termine de ejecutar func de view model

    // Le dice a Flutter que ya terminó de cargar, así que debe actualizar la pantalla para mostrar los ejercicios (y quitar el círculo de carga).
    setState(() {
      isLoading = false;
    });
  }

  // funcion que se llama autom. cuando pantalla se va a cerrar o destruir
  @override
  void dispose() {
    _searchController.dispose(); // liberamos recursos
    super.dispose(); // llama a func. original de flutter para cerrar bien
  }

  //Funcion que renderiza pantalla cada que algo cambia
  @override
  Widget build(BuildContext context) {
    //Si los ejercicios todavía se están cargando, muestra un círculo de carga en el centro de la pantalla.
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _SheetDragHandle(), // barra para indicar que ventana se puede arrastrar
          _SelectorHeader(
            onClose: () => Navigator.of(context).pop(),
          ), //encabezado con titulo y boton para cerrar, si cerramos, nos devuelve a pantalla anterior
          _SearchBar(
            controller:
                _searchController, //Obtenemos contenido de barra de busqueda
            onChanged: (value) => setState(
              () => _searchQuery = value,
            ), // si se cambia, actualizamos var searchQuery
          ),
          _CategoryFilterRow(
            selectedCategory: _selectedCategory,
            onCategorySelected: (cat) =>
                setState(() => _selectedCategory = cat),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _ExerciseResultList(
              exercises: _filteredExercises,
              onExerciseSelected: (exercise) => Navigator.of(
                context,
              ).pop(exercise), // se toma para añadir a rutina
            ),
          ),
          _CreateExerciseButton(
            onPressed: () {
              // TODO: navigate to create exercise screen
            },
          ),
        ],
      ),
    );
  }
}

// stateless porque es la barra
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

class _SelectorHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _SelectorHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Nueva rutina', style: AppTextStyles.screenTitle),
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: 'Buscar ejercicio...',
          hintStyle: AppTextStyles.hintText,
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textHint,
            size: 20,
          ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        itemCount: MuscleGroup.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final category = muscleGroupToString(MuscleGroup.values[index]);
          final isSelected = category == selectedCategory;
          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: AppRadius.chip,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                category,
                style: AppTextStyles.chipLabel.copyWith(
                  color: isSelected
                      ? AppColors.surface
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
        child: Text(
          'No se encontraron ejercicios',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) => _ExerciseResultCard(
        exercise: exercises[index],
        onAdd: () => onExerciseSelected(exercises[index]),
      ),
    );
  }
}

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
          _ExerciseAvatar(initials: 'Ex', imageUrl: exercise.imageUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: AppTextStyles.exerciseName),
                const SizedBox(height: 2),
                // Text(exercise.subtitle, style: AppTextStyles.exerciseSubtitle),
                // const SizedBox(height: AppSpacing.xs),
                _CategoryTag(label: exercise.primaryMuscleName),
              ],
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const Icon(Icons.add, color: AppColors.primary, size: 24),
          ),
        ],
      ),
    );
  }
}

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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : Text(
                initials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;

  const _CategoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.tagBackground,
        borderRadius: AppRadius.chip,
      ),
      child: Text(label, style: AppTextStyles.tagLabel),
    );
  }
}

// ─────────────────────────────────────────────
//  CREATE EXERCISE BUTTON (bottom of selector) este boton es para crear nuevo ejercicio (porque los propuestos por api no son suficientes) -> todavia no se ha implementado lógica
// ─────────────────────────────────────────────
class _CreateExerciseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateExerciseButton({required this.onPressed});

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
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
          label: const Text(
            'Crear ejercicio',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
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
