import 'package:flutter/material.dart';
import '../../models/nutrition/meal_record.dart';
import '../../repositories/nutrition/nutrition_service.dart';

class AddMealScreen extends StatefulWidget {
  final int athleteId;
  final String selectedDate;

  const AddMealScreen({
    super.key,
    required this.athleteId,
    required this.selectedDate,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final NutritionService _service = NutritionService();

  final _foodNameCtrl = TextEditingController();
  final _portionCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  String _mealType = 'breakfast';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _mealTypes = [
    {'value': 'breakfast', 'label': 'Desayuno', 'icon': Icons.free_breakfast},
    {'value': 'lunch', 'label': 'Almuerzo', 'icon': Icons.lunch_dining},
    {'value': 'dinner', 'label': 'Cena', 'icon': Icons.dinner_dining},
    {'value': 'snack', 'label': 'Snack', 'icon': Icons.apple},
  ];

  @override
  void dispose() {
    _foodNameCtrl.dispose();
    _portionCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final meal = MealRecord(
        athlete: widget.athleteId,
        mealType: _mealType,
        foodName: _foodNameCtrl.text.trim(),
        portionGrams: double.parse(_portionCtrl.text),
        calories: double.parse(_caloriesCtrl.text),
        proteinG: _proteinCtrl.text.isNotEmpty
            ? double.tryParse(_proteinCtrl.text)
            : null,
        carbsG: _carbsCtrl.text.isNotEmpty
            ? double.tryParse(_carbsCtrl.text)
            : null,
        fatG: _fatCtrl.text.isNotEmpty ? double.tryParse(_fatCtrl.text) : null,
        date: widget.selectedDate,
      );
      await _service.createMeal(meal);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la comida.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE91E63),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(color: Color(0xFFE91E63)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Agregar Comida',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fecha
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFFE91E63),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.selectedDate,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tipo de comida
              const Text(
                'Tipo de comida',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: _mealTypes.map((type) {
                  final selected = _mealType == type['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _mealType = type['value'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE91E63)
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFE91E63)
                                : Colors.white12,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type['label'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Nombre
              _buildField(
                controller: _foodNameCtrl,
                label: 'Nombre del alimento',
                hint: 'Ej: Arroz con pollo',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),

              // Porción y calorías
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _portionCtrl,
                      label: 'Porción (g)',
                      hint: '200',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _caloriesCtrl,
                      label: 'Calorías (kcal)',
                      hint: '350',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Macros
              const Text(
                'Macronutrientes (opcional)',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _proteinCtrl,
                      label: 'Proteína (g)',
                      hint: '40',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      controller: _carbsCtrl,
                      label: 'Carbos (g)',
                      hint: '60',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField(
                      controller: _fatCtrl,
                      label: 'Grasas (g)',
                      hint: '15',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Guardar comida',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
