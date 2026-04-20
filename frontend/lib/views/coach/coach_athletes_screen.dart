import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../routine/routine_detail_screen.dart';

class CoachAthletesScreen extends StatefulWidget {
  const CoachAthletesScreen({super.key});

  @override
  State<CoachAthletesScreen> createState() => CoachAthletesScreenState();
}

class CoachAthletesScreenState extends State<CoachAthletesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _myAthletes = [];
  bool _isSearching = false;
  bool _isLoadingMyAthletes = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => _isLoadingMyAthletes = true);
    try {
      final response = await ApiClient.dio.get('users/coach/athletes/');
      setState(() => _myAthletes = response.data);
    } catch (e) {
      debugPrint("Error fetching my athletes: $e");
    } finally {
      setState(() => _isLoadingMyAthletes = false);
    }
  }

  Future<void> _searchAthletes(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final response = await ApiClient.dio.get('users/athletes/search/', queryParameters: {'q': query});
      setState(() => _searchResults = response.data);
    } catch (e) {
      debugPrint("Error searching athletes: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _linkAthlete(int id) async {
    try {
      await ApiClient.dio.post('users/coach/athletes/$id/');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Atleta vinculado correctamente")),
      );
      refresh();
      setState(() {
        _searchResults = [];
        _searchController.clear();
      });
    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al vincular atleta")),
      );
    }
  }

  Future<void> _viewAthleteRoutine(int athleteId) async {
    setState(() => _isLoadingMyAthletes = true);
    try {
      final response = await ApiClient.dio.get('athletes/$athleteId/routine/');
      if (mounted) {
        // Asumiendo que RoutineDetailScreen acepta un objeto de tipo RoutineModel
        // Necesitaremos convertir el response.data a RoutineModel o manejarlo
        // De momento, si el backend devuelve el detalle completo:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoutineDetailScreenFromId(routineId: response.data['id']),
          ),
        ).then((deleted) {
          if (deleted == true) refresh();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Este atleta aún no tiene una rutina asignada.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMyAthletes = false);
    }
  }

  Future<void> _showQuickAssignModal(int athleteId) async {
    try {
      final response = await ApiClient.dio.get('routines/');
      final List<dynamic> routines = response.data;

      if (!mounted) return;

      if (routines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aún no tienes rutinas creadas. Ve a la pestaña Rutinas.")),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("Selecciona una Rutina", style: AppTextStyles.h2),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      return ListTile(
                        title: Text(routine['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(routine['category'] ?? ''),
                        trailing: const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await ApiClient.dio.post(
                              'routines/${routine['id']}/assign/', 
                              data: {'athlete_ids': [athleteId]}
                            );

                            refresh();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Rutina asignada!")));
                            }
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al asignar rutina.")));
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al cargar rutinas.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05), // Indented inner look
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primary, // Vibrant Orange active background
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4), // Glow effect
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelColor: Colors.white, // Text inside orange pill
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.fitnessBold.copyWith(fontSize: 11),
                  unselectedLabelStyle: AppTextStyles.fitnessBold.copyWith(fontSize: 11),
                  tabs: const [
                    Tab(text: "BUSCADOR", height: 40),
                    Tab(text: "POR ASIGNAR", height: 40),
                    Tab(text: "ENTRENANDO", height: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBuscadorTab(),
                    _buildPorAsignarTab(),
                    _buildEntrenandoTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPorAsignarTab() {
    final pending = _myAthletes.where((a) => a['active_routine_id'] == null).toList();
    return _buildTabContainer(
      title: "ATLETAS SIN PLAN",
      subtitle: "ESTOS ATLETAS NECESITAN UNA RUTINA ACTIVA",
      child: _buildAthletesList(pending, isPending: true),
    );
  }

  Widget _buildEntrenandoTab() {
    final active = _myAthletes.where((a) => a['active_routine_id'] != null).toList();
    return _buildTabContainer(
      title: "PLANES ACTIVOS",
      subtitle: "ATLETAS QUE YA ESTÁN ENTRENANDO",
      child: _buildAthletesList(active, isPending: false),
    );
  }

  Widget _buildBuscadorTab() {
    return _buildTabContainer(
      title: "BUSCADOR GLOBAL",
      subtitle: "TRAE NUEVOS ATLETAS A TU PANEL",
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _searchAthletes,
            decoration: InputDecoration(
              hintText: "Nombre o email...",
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _isSearching ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ) : null,
            ),
          ),
          const SizedBox(height: 24),
          if (_searchResults.isNotEmpty) _buildSearchResults(),
          if (_searchResults.isEmpty && !_isSearching) 
             Center(
               child: Padding(
                 padding: const EdgeInsets.all(40),
                 child: Icon(Icons.person_search_rounded, size: 80, color: AppColors.textHint.withValues(alpha: 0.2)),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildTabContainer({required String title, required String subtitle, required Widget child}) {
    return RefreshIndicator(
      onRefresh: refresh,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 32),
          Text(title, style: AppTextStyles.fitnessDisplay.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.fitnessCaption),
          const SizedBox(height: 32),
          child,
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.softShadow,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = _searchResults[index];
          final isAlreadyLinked = _myAthletes.any((a) => a['id'] == user['id']);
          
          return ListTile(
            title: Text(user['name'] ?? user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user['email']),
            trailing: isAlreadyLinked 
              ? const Icon(Icons.check_circle_rounded, color: Colors.green)
              : ElevatedButton(
                  onPressed: () => _linkAthlete(user['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text("Vincular", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
          );
        },
      ),
    );
  }

  Widget _buildAthletesList(List<dynamic> athletes, {required bool isPending}) {
    if (_isLoadingMyAthletes) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (athletes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(
                isPending ? Icons.notification_important_rounded : Icons.fitness_center_rounded, 
                size: 64, 
                color: AppColors.textHint.withValues(alpha: 0.3)
              ),
              const SizedBox(height: 16),
              Text(
                isPending ? "Todos tus atletas tienen planes." : "Aún no tienes atletas entrenando.", 
                style: const TextStyle(color: AppColors.textSecondary)
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: athletes.length,
      itemBuilder: (context, index) {
        final athlete = athletes[index];
        final routineTitle = athlete['active_routine_title'] ?? "Sin rutina";

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isPending 
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(
              color: isPending ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent, 
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPending 
                      ? [AppColors.primary.withValues(alpha: 0.8), AppColors.primary]
                      : [AppColors.textHint.withValues(alpha: 0.2), AppColors.textHint.withValues(alpha: 0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    athlete['name']?[0]?.toUpperCase() ?? 'A', 
                    style: TextStyle(
                      color: isPending ? Colors.white : AppColors.textSecondary, 
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    )
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(athlete['name'] ?? athlete['username'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("REQUIERE ACCIÓN", style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      )
                    else
                      Text(
                        "Plan Activo:\n$routineTitle", 
                        style: TextStyle(color: AppColors.primary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600, height: 1.2)
                      ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isPending ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: isPending 
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
                ),
                child: IconButton(
                  icon: Icon(
                    isPending ? Icons.add_rounded : Icons.arrow_forward_ios_rounded, 
                    color: isPending ? Colors.white : AppColors.textSecondary,
                    size: isPending ? 24 : 16,
                  ),
                  onPressed: () {
                    if (isPending) {
                      _showQuickAssignModal(athlete['id']);
                    } else {
                      _viewAthleteRoutine(athlete['id']);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
