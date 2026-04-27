import 'package:flutter/material.dart';
import '../../../view_models/dashboard/dashboard_view_model.dart';

class CoachProfileWidget extends StatefulWidget {
  final DashboardViewModel vm;

  const CoachProfileWidget({super.key, required this.vm});

  @override
  State<CoachProfileWidget> createState() => _CoachProfileWidgetState();
}

class _CoachProfileWidgetState extends State<CoachProfileWidget> {
  final TextEditingController _groupNameCtrl = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _groupNameCtrl.text.trim();

    if (name.isEmpty) return;

    setState(() => _isCreating = true);

    try {
      await widget.vm.createGroup(name);

      _groupNameCtrl.clear();

      if (!mounted) return;

      Navigator.pop(context);

      // 🔄 recargar dashboard
      await widget.vm.loadCoachDashboard();

      setState(() {});
    } catch (e) {
      // puedes mostrar error
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _openCreateGroupDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Crear grupo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _groupNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo',
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createGroup,
                    child: _isCreating
                        ? const CircularProgressIndicator()
                        : const Text('Crear'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.vm.coachDashboard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil Coach',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        if (d == null)
          const Text('Sin datos')
        else ...[
          Text('Especialidad: ${d.speciality}'),
          Text('Experiencia: ${d.yearsExperience} años'),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis grupos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _openCreateGroupDialog,
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (d.groups.isEmpty)
            const Text('No tienes grupos')
          else
            ...d.groups.map(
              (g) => Card(
                child: ListTile(
                  leading: const Icon(Icons.group),
                  title: Text(g.name),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
