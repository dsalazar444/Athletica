import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../routine/routine_detail_screen.dart';
import '../group/groups_screen.dart';

class CoachAthletesScreen extends StatefulWidget {
  const CoachAthletesScreen({super.key});

  @override
  State<CoachAthletesScreen> createState() => CoachAthletesScreenState();
}

class CoachAthletesScreenState extends State<CoachAthletesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _myAthletes = [];
  List<dynamic> _myGroups = [];
  bool _isSearching = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);
    try {
      final futures = [
        ApiClient.dio.get('users/coach/athletes/'),
        ApiClient.dio.get('groups/'),
      ];
      final results = await Future.wait(futures);
      if (mounted) {
        setState(() {
          _myAthletes = results[0].data;
          _myGroups = results[1].data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching coach data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _searchAthletes(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final response = await ApiClient.dio.get(
        'users/athletes/search/',
        queryParameters: {'q': query},
      );
      final List<dynamic> athletes = response.data;
      final List<dynamic> matchingGroups = _myGroups
          .where(
            (g) => g['name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();

      setState(() {
        _searchResults = [
          ...matchingGroups.map((g) => {...g, 'isGroup': true}),
          ...athletes.map((a) => {...a, 'isGroup': false}),
        ];
      });
    } catch (e) {
      debugPrint("Error searching: $e");
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al vincular atleta")));
    }
  }

  Future<void> _viewAthleteRoutine(int athleteId) async {
    if (mounted) setState(() => _isLoadingData = true);
    try {
      final response = await ApiClient.dio.get('athletes/$athleteId/routine/');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RoutineDetailScreenFromId(routineId: response.data['id']),
          ),
        ).then((deleted) {
          if (deleted == true) refresh();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Este atleta aún no tiene una rutina asignada."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _showQuickAssignNutritionModal(int id, {bool isGroup = false}) async {
    try {
      final response = await ApiClient.dio.get('nutrition/plans/');
      final List<dynamic> plans = response.data;

      if (!mounted) return;
      if (plans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aún no tienes planes nutricionales creados."),
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text("Asignar Plan Nutricional", style: AppTextStyles.h2),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return ListTile(
                      title: Text(
                        plan['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${(plan['target_calories'] as num).toStringAsFixed(0)} kcal · P:${(plan['protein_g'] as num).toStringAsFixed(0)}g · C:${(plan['carbs_g'] as num).toStringAsFixed(0)}g · G:${(plan['fat_g'] as num).toStringAsFixed(0)}g",
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await ApiClient.dio.post(
                            'nutrition/plans/${plan['id']}/assign/',
                            data: {
                              if (isGroup) 'group_ids': [id] else 'athlete_ids': [id],
                            },
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("¡Plan nutricional asignado!"),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Error al asignar el plan."),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al cargar los planes.")),
        );
      }
    }
  }

  Future<void> _showQuickAssignModal(int id, {bool isGroup = false}) async {
    try {
      final response = await ApiClient.dio.get('routines/');
      final List<dynamic> routines = response.data;

      if (!mounted) return;
      if (routines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aún no tienes rutinas creadas.")),
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
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    isGroup ? "Asignar a Grupo" : "Asignar a Atleta",
                    style: AppTextStyles.h2,
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      return ListTile(
                        title: Text(
                          routine['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(routine['category'] ?? ''),
                        trailing: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await ApiClient.dio.post(
                              'routines/${routine['id']}/assign/',
                              data: {
                                if (isGroup)
                                  'group_ids': [id]
                                else
                                  'athlete_ids': [id],
                              },
                            );
                            refresh();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("¡Rutina asignada!"),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Error al asignar rutina."),
                                ),
                              );
                            }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al cargar rutinas.")),
        );
      }
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
              _buildTabs(),
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

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.fitnessBold.copyWith(fontSize: 11),
        tabs: const [
          Tab(text: "BUSCADOR", height: 40),
          Tab(text: "POR ASIGNAR", height: 40),
          Tab(text: "ENTRENANDO", height: 40),
        ],
      ),
    );
  }

  Widget _buildBuscadorTab() {
    return _buildTabContainer(
      title: "BUSCADOR GLOBAL",
      subtitle: "ENCUENTRA ATLETAS O TUS GRUPOS",
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _searchAthletes,
            decoration: const InputDecoration(
              hintText: "Nombre, email o grupo...",
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 24),
          if (_searchResults.isNotEmpty) _buildSearchResults(),
          if (_searchResults.isEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Icon(
                Icons.search_off_rounded,
                size: 80,
                color: AppColors.textHint.withValues(alpha: 0.2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final bool isGroup = item['isGroup'] == true;
        final bool isAlreadyLinked =
            !isGroup && _myAthletes.any((a) => a['id'] == item['id']);

        return _buildEntityCard(
          item,
          isGroup,
          false,
          trailing: isAlreadyLinked
              ? const Icon(Icons.check_circle_rounded, color: Colors.green)
              : IconButton(
                  icon: Icon(
                    isGroup
                        ? Icons.group_add_rounded
                        : Icons.person_add_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => isGroup
                      ? _showQuickAssignModal(item['id'], isGroup: true)
                      : _linkAthlete(item['id']),
                ),
        );
      },
    );
  }

  Widget _buildPorAsignarTab() {
    // 1. Identificar atletas que ya pertenecen a un grupo
    final idsInGroups = _myGroups
        .expand((g) => g['members'] as List)
        .map((m) => m['id'])
        .toSet();

    // 2. Atletas pendientes que NO tienen grupo
    final independentPending = _myAthletes
        .where(
          (a) =>
              a['active_routine_id'] == null && !idsInGroups.contains(a['id']),
        )
        .toList();

    final pendingGroups = _myGroups.where((g) {
      final members = g['members'] as List;
      if (members.isEmpty) return true;
      return members.any((m) => m['active_routine_id'] == null);
    }).toList();

    return _buildTabContainer(
      title: "GESTIÓN GRUPAL",
      subtitle: "ASIGNA RUTINAS A EQUIPOS O INDIVIDUOS",
      child: _buildCompositionList(
        athletes: independentPending,
        groups: pendingGroups,
        isPending: true,
      ),
    );
  }

  Widget _buildEntrenandoTab() {
    // 1. Identificar atletas que ya pertenecen a un grupo
    final idsInGroups = _myGroups
        .expand((g) => g['members'] as List)
        .map((m) => m['id'])
        .toSet();

    // 2. Atletas activos que NO tienen grupo
    final independentActive = _myAthletes
        .where(
          (a) =>
              a['active_routine_id'] != null && !idsInGroups.contains(a['id']),
        )
        .toList();

    final trainingGroups = _myGroups.where((g) {
      final members = g['members'] as List;
      if (members.isEmpty) return false;
      return members.every((m) => m['active_routine_id'] != null);
    }).toList();

    return _buildTabContainer(
      title: "CONTROL ACTIVO",
      subtitle: "ESTADO DE ENTRENAMIENTO EN TIEMPO REAL",
      child: _buildCompositionList(
        athletes: independentActive,
        groups: trainingGroups,
        isPending: false,
      ),
    );
  }

  Widget _buildCompositionList({
    required List<dynamic> athletes,
    required List<dynamic> groups,
    required bool isPending,
  }) {
    if (_isLoadingData) return const Center(child: CircularProgressIndicator());
    final List<dynamic> combined = [
      ...groups.map((g) => {...g, 'isGroup': true}),
      ...athletes.map((a) => {...a, 'isGroup': false}),
    ];
    if (combined.isEmpty) return _buildEmptyState(isPending);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: combined.length,
      itemBuilder: (context, index) {
        final item = combined[index];
        return _buildEntityCard(item, item['isGroup'] == true, isPending);
      },
    );
  }

  Widget _buildEntityCard(
    dynamic item,
    bool isGroup,
    bool isPending, {
    Widget? trailing,
  }) {
    final title = item['name'] ?? item['username'] ?? "Sin nombre";
    final subtitle = isGroup
        ? "${(item['members'] as List).length} integrantes"
        : (item['active_routine_title'] ?? "Sin rutina activa");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
        border: Border.all(
          color: isGroup
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: () =>
            isGroup ? _showGroupDetail(item) : _viewAthleteRoutine(item['id']),
        leading: _buildEntityIcon(isGroup),
        title: Text(
          title,
          style: AppTextStyles.fitnessBold.copyWith(fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isGroup ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        trailing: trailing ??
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'routine') {
                  _showQuickAssignModal(item['id'], isGroup: isGroup);
                } else if (value == 'nutrition') {
                  _showQuickAssignNutritionModal(item['id'], isGroup: isGroup);
                } else if (value == 'manage') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyGroupsScreen()),
                  ).then((_) => refresh());
                }
              },
              itemBuilder: (_) => [
                if (isGroup)
                  const PopupMenuItem(
                    value: 'manage',
                    child: ListTile(
                      leading: Icon(Icons.manage_accounts_rounded),
                      title: Text("Gestionar grupo"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'routine',
                  child: ListTile(
                    leading: Icon(Icons.fitness_center_rounded),
                    title: Text("Asignar rutina"),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'nutrition',
                  child: ListTile(
                    leading: Icon(Icons.restaurant_menu_rounded),
                    title: Text("Asignar plan nutricional"),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildEntityIcon(bool isGroup) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isGroup
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.textHint.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isGroup ? Icons.groups_rounded : Icons.person_rounded,
        color: isGroup ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
    );
  }

  void _showGroupDetail(dynamic group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  group['name'].toString().toUpperCase(),
                  style: AppTextStyles.fitnessDisplay,
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyGroupsScreen(),
                      ),
                    ).then((_) => refresh());
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                  label: const Text("Gestionar"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: (group['members'] as List).length,
                itemBuilder: (context, index) {
                  final member = group['members'][index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member['name'] ?? member['username']),
                    onTap: () {
                      Navigator.pop(context);
                      _viewAthleteRoutine(member['id']);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 32),
          Text(
            title,
            style: AppTextStyles.fitnessDisplay.copyWith(fontSize: 22),
          ),
          Text(subtitle, style: AppTextStyles.fitnessCaption),
          const SizedBox(height: 24),
          child,
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isPending) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text(
          isPending ? "No hay pendientes." : "Sin actividad.",
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
