import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class NutritionAssignmentBottomSheet extends StatefulWidget {
  final int planId;
  final String planTitle;
  final VoidCallback onSuccess;

  const NutritionAssignmentBottomSheet({
    super.key,
    required this.planId,
    required this.planTitle,
    required this.onSuccess,
  });

  @override
  State<NutritionAssignmentBottomSheet> createState() =>
      _NutritionAssignmentBottomSheetState();
}

class _NutritionAssignmentBottomSheetState
    extends State<NutritionAssignmentBottomSheet> {
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
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient.dio.get('users/coach/athletes/'),
        ApiClient.dio.get('groups/'),
      ]);
      if (mounted) {
        setState(() {
          _athletes = results[0].data;
          _groups = results[1].data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assign() async {
    if (_selectedAthletes.isEmpty && _selectedGroups.isEmpty) return;
    setState(() => _isAssigning = true);
    try {
      await ApiClient.dio.post(
        'nutrition/plans/${widget.planId}/assign/',
        data: {
          'athlete_ids': _selectedAthletes,
          'group_ids': _selectedGroups,
        },
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al asignar el plan")),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _selectedAthletes.length + _selectedGroups.length;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ASIGNAR PLAN", style: AppTextStyles.fitnessBold),
                    Text(
                      widget.planTitle,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [Tab(text: "ATLETAS"), Tab(text: "GRUPOS")],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(_athletes, _selectedAthletes, "No tienes atletas vinculados."),
                  _buildList(_groups, _selectedGroups, "No tienes grupos creados."),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: total == 0 || _isAssigning ? null : _assign,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<dynamic> items,
    List<int> selected,
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
        final id = item['id'] as int;
        final isSelected = selected.contains(id);
        final title = item['name'] ?? item['username'] ?? '';
        final subtitle = item['email'] ??
            "${(item['members'] as List?)?.length ?? 0} miembros";
        return CheckboxListTile(
          value: isSelected,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                selected.add(id);
              } else {
                selected.remove(id);
              }
            });
          },
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}
