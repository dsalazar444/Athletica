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
  final List<int> _selectedAthletes = [];
  bool _isLoading = false;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _fetchAthletes();
  }

  Future<void> _fetchAthletes() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.get('users/coach/athletes/');
      if (mounted) setState(() => _athletes = response.data);
    } catch (e) {
      debugPrint("Error fetching athletes: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignRoutine() async {
    if (_selectedAthletes.isEmpty) return;
    if (mounted) setState(() => _isAssigning = true);
    try {
      await ApiClient.dio.post(
        'routines/${widget.routine.id}/assign/',
        data: {'athlete_ids': _selectedAthletes.toList()},
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Text("Selecciona los atletas para: ${widget.routine.title}", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          _buildAthletesList(),
          const SizedBox(height: 24),
          _buildConfirmButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("ASIGNAR RUTINA", style: AppTextStyles.fitnessBold),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
      ],
    );
  }

  Widget _buildAthletesList() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }
    
    if (_athletes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("No tienes atletas vinculados todavía."),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _athletes.length,
        itemBuilder: (context, index) {
          final athlete = _athletes[index];
          final isSelected = _selectedAthletes.contains(athlete['id']);
          return CheckboxListTile(
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedAthletes.add(athlete['id']);
                } else {
                  _selectedAthletes.remove(athlete['id']);
                }
              });
            },
            title: Text(athlete['name'] ?? athlete['username']),
            subtitle: Text(athlete['email']),
            activeColor: AppColors.primary,
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedAthletes.isEmpty || _isAssigning ? null : _assignRoutine,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        child: _isAssigning 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text("CONFIRMAR ASIGNACIÓN (${_selectedAthletes.length})"),
      ),
    );
  }
}
