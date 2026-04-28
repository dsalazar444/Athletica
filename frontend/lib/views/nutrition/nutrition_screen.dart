import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/nutrition/meal_record.dart';
import '../../repositories/nutrition/nutrition_service.dart';
import '../../theme/app_colors.dart';
import 'add_meal_screen.dart';

class NutritionScreen extends StatefulWidget {
  final int athleteId;

  const NutritionScreen({super.key, required this.athleteId});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final NutritionService _service = NutritionService();
  List<MealRecord> _meals = [];
  Map<String, dynamic>? _nutritionPlan;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMeals();
    _fetchNutritionPlan();
  }

  Future<void> _fetchNutritionPlan() async {
    try {
      final response = await ApiClient.dio.get('nutrition/plans/');
      final List<dynamic> plans = response.data;
      if (mounted && plans.isNotEmpty) {
        setState(() => _nutritionPlan = plans.first);
      }
    } catch (_) {}
  }

  String get _formattedDate =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _fetchMeals() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final meals = await _service.getMeals(
        date: _formattedDate,
        athleteId: widget.athleteId,
      );
      if (mounted) {
        setState(() {
          _meals = meals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('No se pudieron cargar los registros.');
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchMeals();
    }
  }

  Future<void> _deleteMeal(int id) async {
    try {
      await _service.deleteMeal(id);
      _fetchMeals();
    } catch (e) {
      _showError('No se pudo eliminar el registro.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double get _totalCalories => _meals.fold(0, (sum, m) => sum + m.calories);

  IconData _mealIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.apple;
    }
  }

  String _mealLabel(String type) {
    const labels = {
      'breakfast': 'Desayuno',
      'lunch': 'Almuerzo',
      'dinner': 'Cena',
      'snack': 'Snack',
    };
    return labels[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Registro de Alimentación',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: Colors.white,
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_totalCalories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Plan nutricional del coach
          if (_nutritionPlan != null) _NutritionPlanBanner(plan: _nutritionPlan!),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _meals.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay comidas registradas para esta fecha.',
                          style: TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                          bottom: 120,
                        ),
                        itemCount: _meals.length,
                        itemBuilder: (context, index) {
                          final meal = _meals[index];
                          return _MealCard(
                            meal: meal,
                            icon: _mealIcon(meal.mealType),
                            label: _mealLabel(meal.mealType),
                            onDelete: () => _deleteMeal(meal.id!),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nutrition_fab',
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddMealScreen(
                athleteId: widget.athleteId,
                selectedDate: _formattedDate,
              ),
            ),
          );
          if (added == true) _fetchMeals();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar comida',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _NutritionPlanBanner extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _NutritionPlanBanner({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'OBJETIVOS DEL ENTRENADOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroTarget(
                label: 'Calorías',
                value: '${plan['target_calories'].toStringAsFixed(0)}',
                unit: 'kcal',
                icon: Icons.local_fire_department_rounded,
              ),
              _MacroTarget(
                label: 'Proteínas',
                value: '${plan['protein_g'].toStringAsFixed(0)}',
                unit: 'g',
                icon: Icons.fitness_center_rounded,
              ),
              _MacroTarget(
                label: 'Carbos',
                value: '${plan['carbs_g'].toStringAsFixed(0)}',
                unit: 'g',
                icon: Icons.grain_rounded,
              ),
              _MacroTarget(
                label: 'Grasas',
                value: '${plan['fat_g'].toStringAsFixed(0)}',
                unit: 'g',
                icon: Icons.water_drop_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTarget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _MacroTarget({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealRecord meal;
  final IconData icon;
  final String label;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal,
    required this.icon,
    required this.label,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal.foodName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    children: [
                      _Chip('${meal.portionGrams.toStringAsFixed(0)}g'),
                      _Chip('${meal.calories.toStringAsFixed(0)} kcal'),
                      if (meal.proteinG != null)
                        _Chip('P: ${meal.proteinG!.toStringAsFixed(0)}g'),
                      if (meal.carbsG != null)
                        _Chip('C: ${meal.carbsG!.toStringAsFixed(0)}g'),
                      if (meal.fatG != null)
                        _Chip('G: ${meal.fatG!.toStringAsFixed(0)}g'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.black38,
                size: 20,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black54, fontSize: 11),
      ),
    );
  }
}
