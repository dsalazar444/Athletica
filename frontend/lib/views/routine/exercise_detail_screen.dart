import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/routine/routine__exercise_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../repositories/routine/workout_repository.dart';
import '../../view_models/routine/exercise_detail_view_model.dart';
import 'exercise_tracking_screen.dart';
import 'package:intl/intl.dart';
import '../../core/config/api_config.dart';

/// Pantalla que muestra el detalle histórico y el récord personal de un ejercicio específico.
/// Permite visualizar la evolución del usuario y acceder rápidamente al registro de una nueva sesión.
class ExerciseDetailScreen extends StatefulWidget {
  final RoutineExerciseModel routineExercise;
  final int routineId;

  const ExerciseDetailScreen({
    super.key,
    required this.routineExercise,
    required this.routineId,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late ExerciseDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel con el repositorio de entrenamientos.
    _viewModel = ExerciseDetailViewModel(
      workoutRepository: WorkoutRepository(baseUrl: ApiConfig.baseUrl),
      exerciseId: widget.routineExercise.exercise.id,
    );
    _viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ExerciseDetailViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
            label: const Text(
              'Atrás',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          leadingWidth: 100,
        ),
        body: Consumer<ExerciseDetailViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildEstadoActual(vm),
                  const SizedBox(height: 24),
                  _buildDescripcion(),
                  const SizedBox(height: 24),
                  _buildRegistrosRecientes(vm),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Construye el encabezado con el nombre del ejercicio y las iniciales decorativas.
  Widget _buildHeader() {
    final initials = widget.routineExercise.exercise.name
        .substring(0, 2)
        .toUpperCase();
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.routineExercise.exercise.name,
                style: AppTextStyles.h2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.routineExercise.exercise.primaryMuscleName,
                style: AppTextStyles.bodyText1.copyWith(
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tarjeta que muestra el récord personal (PR) y el botón para registrar una nueva sesión.
  Widget _buildEstadoActual(ExerciseDetailViewModel vm) {
    final best = vm.bestRecord;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Mejor Marca',
                  style: AppTextStyles.sectionTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Abre la pantalla de seguimiento para añadir un nuevo registro hoy.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseTrackingScreen(
                        routineExercise: widget.routineExercise,
                        routineId: widget.routineId,
                      ),
                    ),
                  ).then((_) => vm.init()); // Recarga los datos al regresar.
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Registrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                best != null ? '${best['weight']}kg' : '--',
                'Peso Máx',
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStat(best != null ? '${best['reps']}' : '--', 'Reps (PR)'),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para mostrar una métrica con valor y etiqueta.
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h2.copyWith(fontSize: 28)),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Muestra la descripción técnica del ejercicio obtenida de la API.
  Widget _buildDescripcion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Descripción Técnica', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 16),
          Text(
            widget.routineExercise.exercise.description.isEmpty
                ? 'No hay descripción detallada disponible para este ejercicio.'
                : widget.routineExercise.exercise.description,
            style: AppTextStyles.bodyText1.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Lista vertical que muestra las sesiones de entrenamiento pasadas.
  Widget _buildRegistrosRecientes(ExerciseDetailViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historial de Sesiones', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        if (vm.history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Aún no has registrado este ejercicio.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ...vm.history.map((session) {
          final date = DateTime.parse(session['date']);
          final sets = session['sets'] as List;
          // Mostramos el peso y repeticiones de la primera serie como resumen.
          final weight = sets.isNotEmpty ? sets.first['weight'] : '--';
          final reps = sets.isNotEmpty ? sets.first['reps'] : '--';
          final setsCount = sets.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Permite editar el registro de una fecha específica.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseTrackingScreen(
                        routineExercise: widget.routineExercise,
                        routineId: widget.routineId,
                        initialDate: date,
                      ),
                    ),
                  ).then((_) => vm.init());
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM').format(date),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$setsCount series completadas • $reps reps',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${weight}kg',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
