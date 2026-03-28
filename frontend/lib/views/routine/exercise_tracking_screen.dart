import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/routine/routine__exercise_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/routine/exercise_tracking_view_model.dart';
import '../../repositories/routine/workout_repository.dart';
import '../../core/config/api_config.dart';

/// Pantalla para el seguimiento en tiempo real de un ejercicio dentro de una sesión.
/// Permite registrar múltiples series (sets), especificando repeticiones y peso.
/// Soporta la edición de sesiones pasadas seleccionando una fecha diferente.
class ExerciseTrackingScreen extends StatefulWidget {
  final RoutineExerciseModel routineExercise;
  final int routineId;
  final DateTime? initialDate;

  const ExerciseTrackingScreen({
    super.key,
    required this.routineExercise,
    required this.routineId,
    this.initialDate,
  });

  @override
  State<ExerciseTrackingScreen> createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  late ExerciseTrackingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel encargado de la lógica de sincronización de series.
    _viewModel = ExerciseTrackingViewModel(
      workoutRepository: WorkoutRepository(baseUrl: ApiConfig.baseUrl),
      exerciseId: widget.routineExercise.exercise.id,
      routineId: widget.routineId,
      initialDate: widget.initialDate,
    );
    _viewModel.init();
  }

  /// Despliega el selector de fecha para visualizar o editar registros de otros días.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _viewModel.selectedDate) {
      _viewModel.setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ExerciseTrackingViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Registro de Series', style: AppTextStyles.h3),
          actions: [
            // Botón para cambiar la fecha de la sesión actual.
            TextButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.primary,
              ),
              label: Consumer<ExerciseTrackingViewModel>(
                builder: (context, vm, _) {
                  return Text(
                    DateFormat('d MMM').format(vm.selectedDate),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Consumer<ExerciseTrackingViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading)
              return const Center(child: CircularProgressIndicator());

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildExerciseHeader(),
                        const SizedBox(height: 24),
                        _buildTableHeader(),
                        const Divider(height: 1),
                        // Lista dinámica de filas para cada serie.
                        ...List.generate(
                          vm.setsToLog.length,
                          (index) => _buildSetRow(vm, index),
                        ),
                        const SizedBox(height: 16),
                        _buildAddRowButton(vm),
                      ],
                    ),
                  ),
                ),
                _buildSaveButton(vm),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Encabezado con el nombre del ejercicio y grupo muscular.
  Widget _buildExerciseHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.routineExercise.exercise.name,
            style: AppTextStyles.h2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${widget.routineExercise.exercise.primaryMuscleName} • Registra tu progreso',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Cabecera informativa para las columnas de la tabla de series.
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Text(
              'SERIE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'REPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'PESO (kg)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// Construye una fila editable para una serie específica.
  Widget _buildSetRow(ExerciseTrackingViewModel vm, int index) {
    final set = vm.setsToLog[index];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${set.setNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            // Campo para ingresar repeticiones.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '${set.reps}',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    final reps = int.tryParse(val);
                    if (reps != null) vm.updateSet(index, reps: reps);
                  },
                ),
              ),
            ),
            // Campo para ingresar el peso utilizado.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '${set.weight}',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    final weight = double.tryParse(val);
                    if (weight != null) vm.updateSet(index, weight: weight);
                  },
                ),
              ),
            ),
            // Botón para eliminar la fila de la serie.
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.textHint,
                size: 20,
              ),
              onPressed: () => vm.removeRow(index),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón para añadir una nueva serie vacía al final de la lista.
  Widget _buildAddRowButton(ExerciseTrackingViewModel vm) {
    return TextButton.icon(
      onPressed: vm.addRow,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('AÑADIR SERIE'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  /// Botón inferior persistente para guardar todos los cambios.
  Widget _buildSaveButton(ExerciseTrackingViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: vm.isSaving
              ? null
              : () async {
                  await vm.saveAll();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: vm.isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'GUARDAR CAMBIOS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
