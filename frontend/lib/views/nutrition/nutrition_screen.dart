import 'package:flutter/material.dart';
import '../../models/nutrition/meal_record.dart';
import '../../repositories/nutrition/nutrition_service.dart';
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
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

  String get _formattedDate =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _fetchMeals() async {
    setState(() => _isLoading = true);
    try {
      final meals = await _service.getMeals(
        date: _formattedDate,
        athleteId: widget.athleteId,
      );
      setState(() => _meals = meals);
    } catch (e) {
      _showError('No se pudieron cargar los registros.');
    } finally {
      setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Registro de Alimentación',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Cabecera fecha y calorías totales
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Color(0xFFE91E63),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          color: Colors.white,
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
                      color: Color(0xFFE91E63),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_totalCalories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de comidas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                  )
                : _meals.isEmpty
                ? const Center(
                    child: Text(
                      'No hay comidas registradas para esta fecha.',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
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
        backgroundColor: const Color(0xFFE91E63),
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
      color: const Color(0xFF1E1E1E),
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
                color: const Color(0xFFE91E63).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFE91E63), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal.foodName,
                    style: const TextStyle(
                      color: Colors.white,
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
                color: Colors.white38,
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
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }
}
