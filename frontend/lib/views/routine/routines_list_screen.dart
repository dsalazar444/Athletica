import 'package:flutter/material.dart';
import '../../models/routine/routine_model.dart';
import '../../repositories/routine/routine_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../view_models/routines_list_view_model.dart';
import '../../core/config/api_config.dart';
import 'new_routine_view.dart';
import 'routine_detail_screen.dart';
import 'workout_history_screen.dart';

/// Pantalla que muestra el listado de rutinas del usuario.
/// Permite visualizar un resumen de cada rutina, refrescar la lista y navegar a la creación de nuevas rutinas.
class RoutinesListScreen extends StatefulWidget {
  const RoutinesListScreen({super.key});

  @override
  State<RoutinesListScreen> createState() => _RoutinesListScreenState();
}

class _RoutinesListScreenState extends State<RoutinesListScreen> {
  late final RoutinesListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Inicialización del ViewModel con la configuración de API centralizada.
    _viewModel = RoutinesListViewModel(
      routineRepository: RoutineRepository(baseUrl: ApiConfig.baseUrl),
    );
    // Carga inicial de datos desde el servidor.
    _viewModel.loadRoutines();
    
    // Escuchamos cambios en el ViewModel para redibujar la pantalla.
    _viewModel.addListener(_onViewModelChange);
  }

  void _onViewModelChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  /// Navega a la pantalla de creación de rutina y recarga la lista al volver si hubo cambios.
  Future<void> _navigateAndRefresh() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewRoutineScreen()),
    );
    _viewModel.loadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndRefresh,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Rutina', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el título y subtítulo de la sección.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 32.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Mis Rutinas', 
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Organiza y gestiona tus entrenamientos',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ver historial',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WorkoutHistoryScreen(),
                ),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.history, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  /// Decide qué contenido mostrar según el estado del ViewModel (Carga, Error o Lista).
  Widget _buildContent() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${_viewModel.errorMessage}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
               onPressed: _viewModel.loadRoutines,
               child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_viewModel.routines.isEmpty) {
      return const Center(
        child: Text('No hay rutinas creadas aún.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      itemCount: _viewModel.routines.length,
      itemBuilder: (context, index) {
        final routine = _viewModel.routines[index];
        return _RoutineCard(routine: routine);
      },
    );
  }
}

/// Widget interno para representar cada ítem de rutina en una tarjeta estilizada.
class _RoutineCard extends StatelessWidget {
  final RoutineModel routine;

  const _RoutineCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: () {
            // Navegación al detalle profundo de la rutina seleccionada.
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RoutineDetailScreen(routine: routine),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icono decorativo de la rutina.
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título de la rutina.
                      Text(
                        routine.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Chips informativos de categoría y dificultad.
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildMiniChip(routine.category.toUpperCase(), AppColors.primary.withOpacity(0.1), AppColors.primary),
                          _buildMiniChip(routine.difficulty.toUpperCase(), AppColors.surfaceVariant, AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Descripción corta (si existe).
                      if (routine.description.isNotEmpty) ...[
                        Text(
                          routine.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Indicadores rápidos de tiempo estimado y número de ejercicios.
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildIndicator(Icons.access_time, '45 min'),
                          _buildIndicator(Icons.fitness_center, '${routine.exercises.length} ejers'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para los chips pequeños (Categoría/Dificultad).
  Widget _buildMiniChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Widget auxiliar para los indicadores con icono (Tiempo/Ejercicios).
  Widget _buildIndicator(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
