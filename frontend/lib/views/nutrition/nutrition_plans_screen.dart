import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'widgets/nutrition_assignment_bottom_sheet.dart';

class NutritionPlansScreen extends StatefulWidget {
  const NutritionPlansScreen({super.key});

  @override
  State<NutritionPlansScreen> createState() => NutritionPlansScreenState();
}

class NutritionPlansScreenState extends State<NutritionPlansScreen> {
  List<dynamic> _plans = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiClient.dio.get('nutrition/plans/');
      if (mounted) setState(() => _plans = response.data);
    } catch (e) {
      debugPrint("Error loading plans: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreatePlanModal() async {
    final titleCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("NUEVO PLAN", style: AppTextStyles.fitnessCaption),
              const SizedBox(height: 4),
              Text("Crea un plan nutricional", style: AppTextStyles.fitnessBold),
              const SizedBox(height: 20),
              TextFormField(
                controller: titleCtrl,
                style: AppTextStyles.inputText,
                decoration: _inputDeco("Nombre del plan", Icons.label_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: caloriesCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTextStyles.inputText,
                decoration: _inputDeco(
                  "Calorías objetivo",
                  Icons.local_fire_department_rounded,
                  suffix: "kcal",
                ),
                validator: _numValidator,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: proteinCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.inputText,
                      decoration: _inputDeco(
                        "Proteínas",
                        Icons.fitness_center_rounded,
                        suffix: "g",
                      ),
                      validator: _numValidator,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: carbsCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.inputText,
                      decoration: _inputDeco(
                        "Carbos",
                        Icons.grain_rounded,
                        suffix: "g",
                      ),
                      validator: _numValidator,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: fatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.inputText,
                      decoration: _inputDeco(
                        "Grasas",
                        Icons.water_drop_rounded,
                        suffix: "g",
                      ),
                      validator: _numValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ApiClient.dio.post('nutrition/plans/', data: {
                        'title': titleCtrl.text.trim(),
                        'target_calories': double.parse(caloriesCtrl.text),
                        'protein_g': double.parse(proteinCtrl.text),
                        'carbs_g': double.parse(carbsCtrl.text),
                        'fat_g': double.parse(fatCtrl.text),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        refresh();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Error al crear el plan"),
                          ),
                        );
                      }
                    }
                  },
                  child: Text("CREAR PLAN", style: AppTextStyles.buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  String? _numValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "Requerido";
    if (double.tryParse(v) == null) return "Inválido";
    return null;
  }

  void _openAssign(dynamic plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NutritionAssignmentBottomSheet(
        planId: plan['id'],
        planTitle: plan['title'],
        onSuccess: () {
          refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Plan asignado correctamente!")),
          );
        },
      ),
    );
  }

  Future<void> _deletePlan(int id) async {
    try {
      await ApiClient.dio.delete('nutrition/plans/$id/');
      refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al eliminar el plan")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          heroTag: 'nutrition_plans_fab',
          onPressed: _showCreatePlanModal,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Nuevo Plan',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MIS PLANES", style: AppTextStyles.fitnessDisplay),
                  const SizedBox(height: 4),
                  Text(
                    "GESTIONA Y ASIGNA PLANES NUTRICIONALES",
                    style: AppTextStyles.fitnessCaption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _plans.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                            itemCount: _plans.length,
                            itemBuilder: (context, index) =>
                                _buildPlanCard(_plans[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan['title'] ?? '',
                  style: AppTextStyles.fitnessBold.copyWith(fontSize: 16),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'assign') _openAssign(plan);
                  if (value == 'delete') _deletePlan(plan['id']);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'assign',
                    child: ListTile(
                      leading: Icon(Icons.person_add_rounded),
                      title: Text("Asignar a atleta"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      title: Text("Eliminar",
                          style: TextStyle(color: AppColors.error)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macroChip(
                Icons.local_fire_department_rounded,
                "${(plan['target_calories'] as num).toStringAsFixed(0)} kcal",
              ),
              _macroChip(
                Icons.fitness_center_rounded,
                "P: ${(plan['protein_g'] as num).toStringAsFixed(0)}g",
              ),
              _macroChip(
                Icons.grain_rounded,
                "C: ${(plan['carbs_g'] as num).toStringAsFixed(0)}g",
              ),
              _macroChip(
                Icons.water_drop_rounded,
                "G: ${(plan['fat_g'] as num).toStringAsFixed(0)}g",
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openAssign(plan),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: Text(
                "ASIGNAR  •  ${plan['assigned_count']} atleta${plan['assigned_count'] == 1 ? '' : 's'}",
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 60,
            color: AppColors.textHint.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "CREA UN PLAN PARA ASIGNARLO",
            style: AppTextStyles.fitnessBold.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
