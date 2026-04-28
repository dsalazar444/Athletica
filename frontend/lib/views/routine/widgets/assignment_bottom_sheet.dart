import 'package:flutter/material.dart';
import '../../../../models/routine/routine_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../core/api_client.dart';

class AssignmentBottomSheet extends StatefulWidget {
  final RoutineModel routine;
  final VoidCallback onSuccess;

  const AssignmentBottomSheet({
    super.key,
    required this.routine,
    required this.onSuccess,
  });

  @override
  State<AssignmentBottomSheet> createState() => _AssignmentBottomSheetState();
}

class _AssignmentBottomSheetState extends State<AssignmentBottomSheet> {
  List<dynamic> _athletes = [];
  List<dynamic> _groups = [];
  final List<int> _selectedAthletes = [];
  final List<int> _selectedGroups = [];
  bool _isLoading = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final futures = [
        ApiClient.dio.get('users/coach/athletes/'),
        ApiClient.dio.get('groups/'),
      ];
      final results = await Future.wait(futures);
      if (mounted) {
        setState(() {
          _athletes = results[0].data;
          _groups = results[1].data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching assignment data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignRoutine() async {
    if (_selectedAthletes.isEmpty && _selectedGroups.isEmpty) return;
    if (mounted) setState(() => _isAssigning = true);
    try {
      await ApiClient.dio.post(
        'routines/${widget.routine.id}/assign/',
        data: {'athlete_ids': _selectedAthletes, 'group_ids': _selectedGroups},
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al asignar rutina")),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: "ATLETAS"),
                Tab(text: "GRUPOS"),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(
                    _athletes,
                    _selectedAthletes,
                    "No tienes atletas.",
                  ),
                  _buildList(_groups, _selectedGroups, "No tienes grupos."),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ASIGNAR RUTINA", style: AppTextStyles.fitnessBold),
            Text(
              widget.routine.title,
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildList(
    List<dynamic> items,
    List<int> selectedList,
    String emptyMsg,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(child: Text(emptyMsg));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id'];
        final isSelected = selectedList.contains(id);
        final title = item['name'] ?? item['username'] ?? "Sin nombre";
        final subtitle =
            item['email'] ?? "${item['members']?.length ?? 0} miembros";

        return CheckboxListTile(
          value: isSelected,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                selectedList.add(id);
              } else {
                selectedList.remove(id);
              }
            });
          },
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    final total = _selectedAthletes.length + _selectedGroups.length;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: total == 0 || _isAssigning ? null : _assignRoutine,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isAssigning
            ? const CircularProgressIndicator(color: Colors.white)
            : Text("CONFIRMAR ASIGNACIÓN ($total)"),
      ),
    );
  }
}
