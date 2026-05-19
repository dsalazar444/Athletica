import 'package:flutter/material.dart';
import '../../models/group/group_model.dart';
import '../../models/group/member_model.dart';
import '../../repositories/group/group_repository.dart';
import '../../theme/app_colors.dart';
import '../group/create_group_screen.dart';
import '../../models/group/group_dashboard_model.dart';

class MyGroupsScreen extends StatefulWidget {
  const MyGroupsScreen({super.key});

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final GroupRepository _repo = GroupRepository();
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _repo.getGroups();
      if (mounted) setState(() => _groups = data);
    } catch (e) {
      debugPrint('ERROR cargando grupos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToCreateGroup() async {
    final newGroup = await Navigator.push<GroupModel>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (newGroup != null) await _fetchGroups();
  }

  void _openManageDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (_) =>
          _ManageGroupDialog(group: group, repo: _repo, onSaved: _fetchGroups),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis grupos'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _goToCreateGroup),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _groups.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Sin grupos aún'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _goToCreateGroup,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primer grupo'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchGroups,
              child: DefaultTabController(
                length: _groups.length,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      labelColor: AppColors.primary,
                      indicatorColor: AppColors.primary,
                      tabs: _groups.map((g) => Tab(text: g.name)).toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: _groups.map((group) {
                          return _GroupTabContent(
                            group: group,
                            onManage: () => _openManageDialog(group),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Tab content ───────────────────────────────────────────────────────────────

class _GroupTabContent extends StatefulWidget {
  final GroupModel group;
  final VoidCallback onManage;

  const _GroupTabContent({required this.group, required this.onManage});

  @override
  State<_GroupTabContent> createState() => _GroupTabContentState();
}

class _GroupTabContentState extends State<_GroupTabContent> {
  final GroupRepository _repo = GroupRepository();

  void _openDashboard() {
    showDialog(
      context: context,
      builder: (_) => _GroupDashboardDialog(
        groupId: widget.group.id,
        groupName: widget.group.name,
        repo: _repo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.group.members.length} atleta${widget.group.members.length == 1 ? '' : 's'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _openDashboard,
                    icon: const Icon(Icons.bar_chart_rounded, size: 16),
                    label: const Text('Tablero'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.onManage,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Gestionar'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: widget.group.members.isEmpty
              ? const Center(child: Text('Sin atletas en este grupo'))
              : ListView.builder(
                  itemCount: widget.group.members.length,
                  itemBuilder: (context, index) {
                    final member = widget.group.members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          member.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(member.displayName),
                      subtitle: Text(member.email),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Dialog de gestión ─────────────────────────────────────────────────────────

class _ManageGroupDialog extends StatefulWidget {
  final GroupModel group;
  final GroupRepository repo;
  final VoidCallback onSaved;

  const _ManageGroupDialog({
    required this.group,
    required this.repo,
    required this.onSaved,
  });

  @override
  State<_ManageGroupDialog> createState() => _ManageGroupDialogState();
}

class _ManageGroupDialogState extends State<_ManageGroupDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _searchController;
  late List<MemberModel> _members;
  List<MemberModel> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.group.name);
    _searchController = TextEditingController();
    _members = List.from(widget.group.members);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final results = await widget.repo.searchAthletes(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _searchError = results.isEmpty ? 'No se encontraron atletas' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'Error buscando atletas';
          _isSearching = false;
        });
      }
    }
  }

  void _addMember(MemberModel athlete) {
    if (_members.any((m) => m.id == athlete.id)) return;
    setState(() {
      _members.add(athlete);
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removeMember(MemberModel member) {
    setState(() => _members.removeWhere((m) => m.id == member.id));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await widget.repo.updateGroup(
        widget.group.id,
        name,
        _members.map((m) => m.id).toList(),
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('ERROR guardando grupo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar cambios')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Gestionar grupo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Miembros'),
                Tab(text: 'Editar info'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildMembersTab(), _buildEditTab()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar atleta por username o email',
              prefixIcon: const Icon(
                Icons.person_search,
                color: AppColors.primary,
              ),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        'Resultados',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    ...(_searchResults.map((athlete) {
                      final alreadyAdded = _members.any(
                        (m) => m.id == athlete.id,
                      );
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            athlete.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          athlete.displayName,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          athlete.email,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: alreadyAdded
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              )
                            : GestureDetector(
                                onTap: () => _addMember(athlete),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Añadir',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                      );
                    })),
                  ],
                ),
              ),
            ),
          ],
          if (_searchError != null && _searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _searchError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Miembros del grupo (${_members.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _members.isEmpty
                ? const Center(child: Text('Sin atletas aún'))
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
                          child: Text(
                            member.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(member.displayName),
                        subtitle: Text(member.email),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeMember(member),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'Nombre del grupo',
          labelStyle: const TextStyle(color: AppColors.primary),
          prefixIcon: const Icon(Icons.group, color: AppColors.primary),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Dialog ──────────────────────────────────────────────────────────

class _GroupDashboardDialog extends StatefulWidget {
  final int groupId;
  final String groupName;
  final GroupRepository repo;

  const _GroupDashboardDialog({
    required this.groupId,
    required this.groupName,
    required this.repo,
  });

  @override
  State<_GroupDashboardDialog> createState() => _GroupDashboardDialogState();
}

class _GroupDashboardDialogState extends State<_GroupDashboardDialog> {
  GroupDashboardModel? _dashboard;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.repo.getGroupDashboard(widget.groupId);
      if (mounted) setState(() => _dashboard = data);
    } catch (e) {
      debugPrint('ERROR cargando tablero: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _trendIcon(String trend) {
    switch (trend) {
      case 'up':
        return '↑';
      case 'down':
        return '↓';
      case 'stable':
        return '→';
      default:
        return '—';
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'up':
        return Colors.red;
      case 'down':
        return Colors.green;
      case 'stable':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _goalLabel(String goalType) {
    switch (goalType) {
      case 'lose_weight':
        return 'Perder peso';
      case 'gain_muscle':
        return 'Ganar músculo';
      case 'maintain':
        return 'Mantener';
      case 'endurance':
        return 'Resistencia';
      case 'wellness':
        return 'Bienestar';
      default:
        return goalType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tablero',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (_dashboard != null)
                          Text(
                            '${_dashboard!.totalMembers} atleta${_dashboard!.totalMembers == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // ── Métricas generales ─────────────────────────────────────────
            if (_dashboard != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _GroupMetricCard(
                      label: 'Peso prom.',
                      value: _dashboard!.groupMetrics.avgWeight != null
                          ? '${_dashboard!.groupMetrics.avgWeight} kg'
                          : 'Sin dato',
                      icon: Icons.monitor_weight_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _GroupMetricCard(
                      label: 'Con rutina',
                      value: '${_dashboard!.groupMetrics.totalWithRoutine}',
                      icon: Icons.fitness_center_rounded,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _GroupMetricCard(
                      label: 'Con meta',
                      value: '${_dashboard!.groupMetrics.totalWithGoal}',
                      icon: Icons.flag_rounded,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    _GroupMetricCard(
                      label: 'Con peso',
                      value: '${_dashboard!.groupMetrics.totalWithWeightData}',
                      icon: Icons.bar_chart_rounded,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            // ── Tendencias ─────────────────────────────────────────────────
            if (_dashboard != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    _TrendSummaryCard(
                      label: 'Bajando',
                      count: _dashboard!.athletes
                          .where((a) => a.weightTrend == 'down')
                          .length,
                      icon: Icons.trending_down_rounded,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _TrendSummaryCard(
                      label: 'Subiendo',
                      count: _dashboard!.athletes
                          .where((a) => a.weightTrend == 'up')
                          .length,
                      icon: Icons.trending_up_rounded,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    _TrendSummaryCard(
                      label: 'Estable',
                      count: _dashboard!.athletes
                          .where((a) => a.weightTrend == 'stable')
                          .length,
                      icon: Icons.trending_flat_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _TrendSummaryCard(
                      label: 'Sin dato',
                      count: _dashboard!.athletes
                          .where((a) => a.weightTrend == 'no_data')
                          .length,
                      icon: Icons.remove_rounded,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            // ── Lista atletas ──────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _dashboard == null || _dashboard!.athletes.isEmpty
                  ? const Center(child: Text('Sin atletas en este grupo'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _dashboard!.athletes.length,
                      itemBuilder: (context, index) {
                        final athlete = _dashboard!.athletes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      athlete.displayName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          athlete.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          athlete.email,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetricTile(
                                      icon: Icons.monitor_weight_rounded,
                                      label: 'Peso',
                                      value: athlete.latestWeight != null
                                          ? '${athlete.latestWeight!.weight} kg'
                                          : 'Sin dato',
                                      trailing: athlete.latestWeight != null
                                          ? Text(
                                              _trendIcon(athlete.weightTrend),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _trendColor(
                                                  athlete.weightTrend,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MetricTile(
                                      icon: Icons.flag_rounded,
                                      label: 'Objetivo',
                                      value: athlete.activeGoal != null
                                          ? _goalLabel(
                                              athlete.activeGoal!.goalType,
                                            )
                                          : 'Sin meta',
                                      trailing:
                                          athlete.activeGoal?.targetValue !=
                                              null
                                          ? Text(
                                              '→ ${athlete.activeGoal!.targetValue}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // ignore: use_null_aware_elements
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendSummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _TrendSummaryCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _GroupMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
