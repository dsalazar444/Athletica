import 'package:flutter/material.dart';
import '../../models/group/group_model.dart';
import '../../models/group/member_model.dart';
import '../../repositories/group/group_repository.dart';
import '../../theme/app_colors.dart';
import '../group/create_group_screen.dart';

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

class _GroupTabContent extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onManage;

  const _GroupTabContent({required this.group, required this.onManage});

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
                '${group.members.length} atleta${group.members.length == 1 ? '' : 's'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              FilledButton(
                onPressed: onManage,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Gestionar'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: group.members.isEmpty
              ? const Center(child: Text('Sin atletas en este grupo'))
              : ListView.builder(
                  itemCount: group.members.length,
                  itemBuilder: (context, index) {
                    final member = group.members[index];
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

    // Búsqueda en tiempo real
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
      child: SizedBox(
        width: double.infinity,
        height: 540,
        child: Column(
          children: [
            // Header
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
          // Buscador
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

          // Resultados de búsqueda
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
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

          // Lista de miembros actuales
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
