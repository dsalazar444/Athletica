import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/nutrition/meal_record.dart';
import '../../repositories/nutrition/nutrition_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
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

  double get _totalCalories => _meals.fold(0, (s, m) => s + m.calories);
  double get _totalProtein => _meals.fold(0, (s, m) => s + (m.proteinG ?? 0));
  double get _totalCarbs => _meals.fold(0, (s, m) => s + (m.carbsG ?? 0));
  double get _totalFat => _meals.fold(0, (s, m) => s + (m.fatG ?? 0));

  Map<String, List<MealRecord>> get _mealsByType {
    const order = ['breakfast', 'lunch', 'dinner', 'snack'];
    final grouped = <String, List<MealRecord>>{};
    for (final t in order) {
      final items = _meals.where((m) => m.mealType == t).toList();
      if (items.isNotEmpty) grouped[t] = items;
    }
    return grouped;
  }

  @override
  void initState() {
    super.initState();
    _fetchMeals();
    _fetchNutritionPlan();
  }

  Future<void> _fetchNutritionPlan() async {
    try {
      final res = await ApiClient.dio.get('nutrition/plans/');
      final List<dynamic> plans = res.data;
      if (mounted && plans.isNotEmpty) {
        setState(() => _nutritionPlan = plans.first);
      }
    } catch (_) {}
  }

  String get _formattedDate =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _displayDate {
    const months = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return 'Hoy, ${_selectedDate.day} ${months[_selectedDate.month]}';
    }
    return '${_selectedDate.day} ${months[_selectedDate.month]}';
  }

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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo eliminar.')));
    }
  }

  Future<void> _goAddMeal() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          heroTag: 'nutrition_fab',
          onPressed: _goAddMeal,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Registrar comida',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ── Header (same pattern as Rutinas) ─────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MI ALIMENTACIÓN',
                      style: AppTextStyles.fitnessDisplay.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🥗', style: TextStyle(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'REGISTRO NUTRICIONAL DEL DÍA',
                  style: AppTextStyles.fitnessCaption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Date picker action circle
          _buildActionCircle(Icons.calendar_month_rounded, _pickDate),
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary),
        onPressed: onTap,
      ),
    );
  }

  // ── Body content ─────────────────────────────────────────────────────────
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
      children: [
        // Date + calories hero card (like "MI PLAN COACH")
        _buildDayHeroCard(),
        const SizedBox(height: 16),

        // Coach nutrition plan card
        if (_nutritionPlan != null) ...[
          _buildCoachPlanCard(),
          const SizedBox(height: 24),
        ],

        // Meals or empty state
        if (_meals.isEmpty) _buildEmptyState() else _buildGroupedMeals(),
      ],
    );
  }

  // ── Day hero card (calories + macros summary) ─────────────────────────────
  Widget _buildDayHeroCard() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.deepShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _displayDate,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Text(
                  _totalCalories.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'kcal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_nutritionPlan?['target_calories'] != null) ...[
                  const Spacer(),
                  Text(
                    '/ ${(_nutritionPlan!['target_calories'] as num).toStringAsFixed(0)} objetivo',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            // Macro pills
            Row(
              children: [
                _MacroPill('💪 P', _totalProtein, 'g', Colors.white),
                const SizedBox(width: 8),
                _MacroPill('⚡ C', _totalCarbs, 'g', Colors.white),
                const SizedBox(width: 8),
                _MacroPill('🫒 G', _totalFat, 'g', Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Coach plan card ───────────────────────────────────────────────────────
  Widget _buildCoachPlanCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'OBJETIVOS DEL ENTRENADOR',
                style: AppTextStyles.fitnessCaption.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroTarget(
                emoji: '🔥',
                label: 'Calorías',
                value: (_nutritionPlan!['target_calories'] as num)
                    .toStringAsFixed(0),
                unit: 'kcal',
              ),
              _MacroTarget(
                emoji: '💪',
                label: 'Proteínas',
                value: (_nutritionPlan!['protein_g'] as num).toStringAsFixed(0),
                unit: 'g',
              ),
              _MacroTarget(
                emoji: '⚡',
                label: 'Carbos',
                value: (_nutritionPlan!['carbs_g'] as num).toStringAsFixed(0),
                unit: 'g',
              ),
              _MacroTarget(
                emoji: '🫒',
                label: 'Grasas',
                value: (_nutritionPlan!['fat_g'] as num).toStringAsFixed(0),
                unit: 'g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Image-like card (same as "MIS RUTINAS" card in Rutinas)
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.softShadow,
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=2053&auto=format&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('🥗', style: TextStyle(fontSize: 28)),
                SizedBox(height: 6),
                Text(
                  'SIN COMIDAS HOY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Registra tu primera comida del día',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Section label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AÑADIR RÁPIDO',
              style: AppTextStyles.fitnessBold.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '4 tipos',
              style: AppTextStyles.fitnessCaption.copyWith(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Quick-add grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: [
            _QuickAddCard('🌅', 'Desayuno', _goAddMeal),
            _QuickAddCard('☀️', 'Almuerzo', _goAddMeal),
            _QuickAddCard('🌙', 'Cena', _goAddMeal),
            _QuickAddCard('🍎', 'Snack', _goAddMeal),
          ],
        ),
      ],
    );
  }

  // ── Grouped meals ─────────────────────────────────────────────────────────
  Widget _buildGroupedMeals() {
    final grouped = _mealsByType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COMIDAS DEL DÍA',
              style: AppTextStyles.fitnessBold.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${_meals.length} registros',
              style: AppTextStyles.fitnessCaption.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final entry in grouped.entries) ...[
          _MealGroupHeader(mealType: entry.key),
          for (final meal in entry.value)
            _MealCard(meal: meal, onDelete: () => _deleteMeal(meal.id!)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ── Macro Pill ────────────────────────────────────────────────────────────────
class _MacroPill extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  const _MacroPill(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(0)}$unit',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Macro Target ──────────────────────────────────────────────────────────────
class _MacroTarget extends StatelessWidget {
  final String emoji, label, value, unit;
  const _MacroTarget({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 9, color: AppColors.textHint),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Quick Add Card ────────────────────────────────────────────────────────────
class _QuickAddCard extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _QuickAddCard(this.emoji, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meal Group Header ─────────────────────────────────────────────────────────
class _MealGroupHeader extends StatelessWidget {
  final String mealType;
  const _MealGroupHeader({required this.mealType});

  static const _cfg = {
    'breakfast': ('🌅 Desayuno', AppColors.primary),
    'lunch': ('☀️ Almuerzo', Color(0xFF1976D2)),
    'dinner': ('🌙 Cena', Color(0xFF6A1B9A)),
    'snack': ('🍎 Snack', Color(0xFF2E7D32)),
  };

  @override
  Widget build(BuildContext context) {
    const defaultCfg = ('🍽️ Comida', AppColors.primary);
    final cfg = _cfg[mealType] ?? defaultCfg;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        cfg.$1.toUpperCase(),
        style: TextStyle(
          color: cfg.$2,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ── Meal Card (same visual as RoutineCard) ────────────────────────────────────
class _MealCard extends StatelessWidget {
  final MealRecord meal;
  final VoidCallback onDelete;
  const _MealCard({required this.meal, required this.onDelete});

  String get _mealEmoji {
    switch (meal.mealType) {
      case 'breakfast':
        return '🌅';
      case 'lunch':
        return '☀️';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍽️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Emoji icon (like the orange circle in RoutineCard)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(_mealEmoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Tag(
                      '🔥 ${meal.calories.toStringAsFixed(0)} kcal',
                      AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _Tag(
                      '${meal.portionGrams.toStringAsFixed(0)}g',
                      AppColors.textSecondary,
                    ),
                    if (meal.proteinG != null) ...[
                      const SizedBox(width: 6),
                      _Tag(
                        '💪 P${meal.proteinG!.toStringAsFixed(0)}g',
                        const Color(0xFF1976D2),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
