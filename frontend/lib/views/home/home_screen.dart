import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../core/token_storage.dart';
import '../../core/api_client.dart';
import '../../repositories/nutrition/nutrition_service.dart';
import '../../repositories/routine/workout_repository.dart';

class HomeScreen extends StatefulWidget {
  final bool hasNotification;
  final VoidCallback? onNotificationTap;
  final int? athleteId;
  final int refreshTick;

  const HomeScreen({
    super.key,
    this.hasNotification = false,
    this.onNotificationTap,
    this.athleteId,
    this.refreshTick = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Usuario';
  final NutritionService _nutritionService = NutritionService();
  final WorkoutRepository _workoutRepository = WorkoutRepository(
    baseUrl: ApiClient.baseUrl,
  );

  static const int _calendarDays = 21;
  static const List<String> _weekdayLabels = [
    'L',
    'M',
    'X',
    'J',
    'V',
    'S',
    'D',
  ];

  bool _isCalendarLoading = true;
  Map<String, _DayActivity> _calendarActivity = {};

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadCalendarActivity();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.athleteId != widget.athleteId) {
      _loadCalendarActivity();
    }
  }

  Future<void> _loadUserName() async {
    final name = await TokenStorage.getUserName();
    if (name != null) {
      if (mounted) setState(() => _userName = name);
    }
  }

  Future<void> _loadCalendarActivity() async {
    if (mounted) {
      setState(() => _isCalendarLoading = true);
    }

    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(const Duration(days: _calendarDays - 1));

    try {
      final results = await Future.wait([
        _workoutRepository.fetchWorkoutHistoryByDateRange(
          startDate: start,
          endDate: end,
          page: 1,
          pageSize: 100,
        ),
        _nutritionService.getMeals(
          startDate: _formatDate(start),
          endDate: _formatDate(end),
          athleteId: widget.athleteId,
        ),
      ]);

      final workoutHistory = results[0] as dynamic;
      final meals = results[1] as List<dynamic>;

      final Map<String, _DayActivity> byDay = {
        for (int i = 0; i < _calendarDays; i++)
          _formatDate(start.add(Duration(days: i))): _DayActivity.none,
      };

      for (final item in workoutHistory.results) {
        final key = _formatDate((item.date as DateTime).toLocal());
        final current = byDay[key] ?? _DayActivity.none;
        byDay[key] = _mergeActivity(current, _DayActivity.workout);
      }

      for (final meal in meals) {
        final key = meal.date as String;
        final current = byDay[key] ?? _DayActivity.none;
        byDay[key] = _mergeActivity(current, _DayActivity.nutrition);
      }

      if (mounted) {
        setState(() {
          _calendarActivity = byDay;
          _isCalendarLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _calendarActivity = {
            for (int i = 0; i < _calendarDays; i++)
              _formatDate(start.add(Duration(days: i))): _DayActivity.none,
          };
          _isCalendarLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  _DayActivity _mergeActivity(_DayActivity current, _DayActivity incoming) {
    if (current == incoming) return current;
    if (current == _DayActivity.none) return incoming;
    if (incoming == _DayActivity.none) return current;
    return _DayActivity.both;
  }

  int get _currentStreakDays {
    final now = DateTime.now();
    var streak = 0;

    for (int i = 0; i < _calendarDays; i++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final key = _formatDate(day);
      final activity = _calendarActivity[key] ?? _DayActivity.none;
      if (activity == _DayActivity.none) {
        break;
      }
      streak++;
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("ESTADÍSTICAS DEL DÍA"),
                  const SizedBox(height: 16),
                  _buildBentoGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("CALENDARIO DE RACHA"),
                  const SizedBox(height: 16),
                  _buildStreakCalendar(),
                  const SizedBox(height: 32),
                  // _buildSectionTitle("ENTRENAMIENTO SUGERIDO"),
                  // const SizedBox(height: 16),
                  // _buildFeaturedRoutine(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return SizedBox(
      height: 480,
      width: double.infinity,
      child: Stack(
        children: [
          // Hero Image
          Container(
            height: 480,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_bg_neon.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            height: 480,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                  AppColors.background,
                ],
                stops: const [0.0, 0.75, 1.0],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "HOLA, ${_userName.toUpperCase()}",
                            style: AppTextStyles.fitnessCaption.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black.withValues(alpha: 0.8),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "STRENGTH\n& POWER.",
                            style: AppTextStyles.fitnessHero.copyWith(
                              color: Colors.white,
                              height: 0.9,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black.withValues(alpha: 0.8),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: widget.onNotificationTap,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: Colors.white,
                              ),
                            ),
                            if (widget.hasNotification)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.whiteGlass,
                      borderRadius: AppRadius.card,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "EL ÉXITO COMIENZA AQUÍ",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "¡Listo para tu entrenamiento de hoy?",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.fitnessBold.copyWith(
        color: AppColors.textPrimary,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildBentoGrid() {
    final streakValue = _currentStreakDays.toString();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _bentoItem(
                title: "CALORÍAS",
                value: "1,240",
                unit: "kcal",
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF5252),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _bentoItem(
                title: "TIEMPO",
                value: "45",
                unit: "min",
                icon: Icons.timer_rounded,
                color: const Color(0xFF448AFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _bentoItem(
                title: "RACHAS",
                value: streakValue,
                unit: "días",
                icon: Icons.flash_on_rounded,
                color: const Color(0xFFFFD740),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: _bentoItem(
                title: "PESO ACTUAL",
                value: "78.5",
                unit: "kg",
                icon: Icons.fitness_center_rounded,
                color: const Color(0xFF64FFDA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakCalendar() {
    if (_isCalendarLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          boxShadow: AppColors.deepShadow,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: _calendarDays - 1));

    final days = List.generate(
      _calendarDays,
      (index) => start.add(Duration(days: index)),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.deepShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ultimos 21 dias',
                style: AppTextStyles.fitnessCaption.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '3 semanas',
                style: AppTextStyles.fitnessCaption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: days.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              mainAxisExtent: 68,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final key = _formatDate(day);
              final activity = _calendarActivity[key] ?? _DayActivity.none;
              final isToday =
                  day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    _weekdayLabels[day.weekday - 1],
                    style: AppTextStyles.fitnessCaption.copyWith(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: activity.color,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday
                          ? Border.all(color: AppColors.primaryDark, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: activity.textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _LegendDot(label: 'Ejercicio', activity: _DayActivity.workout),
              _LegendDot(
                label: 'Alimentacion',
                activity: _DayActivity.nutrition,
              ),
              _LegendDot(label: 'Ambos', activity: _DayActivity.both),
              _LegendDot(label: 'Sin actividad', activity: _DayActivity.none),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bentoItem({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.deepShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTextStyles.fitnessDisplay.copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: AppTextStyles.bentoUnit),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.fitnessCaption.copyWith(
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildFeaturedRoutine() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.cardLarge,
        boxShadow: AppColors.mediumShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 180,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "PODER TOTAL",
                    style: AppTextStyles.fitnessCaption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "CSEP: LEGS & GLUTES",
                  style: AppTextStyles.fitnessDisplay.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "45 MIN • ALTA INTENSIDAD",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "COMENZAR AHORA",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
*/
}

enum _DayActivity { none, workout, nutrition, both }

extension _DayActivityStyle on _DayActivity {
  Color get color {
    switch (this) {
      case _DayActivity.workout:
        return const Color(0xFF3B82F6);
      case _DayActivity.nutrition:
        return AppColors.success;
      case _DayActivity.both:
        return AppColors.intensityNeon;
      case _DayActivity.none:
        return AppColors.surfaceVariant;
    }
  }

  Color get textColor {
    switch (this) {
      case _DayActivity.none:
        return AppColors.textSecondary;
      default:
        return Colors.white;
    }
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final _DayActivity activity;

  const _LegendDot({required this.label, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: activity.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
