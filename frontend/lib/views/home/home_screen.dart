import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../core/token_storage.dart';
import '../../core/api_client.dart';
import '../../models/badge/badge_model.dart';
import '../../repositories/badge/badge_repository.dart';
import '../../repositories/nutrition/nutrition_service.dart';
import '../../repositories/routine/workout_repository.dart';
import '../../repositories/routine/recommendation_repository.dart';
import '../../models/routine/exercise_recommendation.dart';
import 'package:lottie/lottie.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
  final BadgeRepository _badgeRepository = BadgeRepository(
    baseUrl: ApiClient.baseUrl,
  );
  final NutritionService _nutritionService = NutritionService();
  final WorkoutRepository _workoutRepository = WorkoutRepository(
    baseUrl: ApiClient.baseUrl,
  );
  final RecommendationRepository _recommendationRepository =
      RecommendationRepository(baseUrl: ApiClient.baseUrl);

  String _userRole = 'athlete';

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

  bool _isAiLoading = true;
  List<ExerciseRecommendation> _aiRecommendations = [];

  bool _isBadgeLoading = true;
  List<BadgeDefinition> _availableBadges = [];
  Set<int> _unlockedBadgeIds = {};
  int _userBadgeCount = 0;
  BadgeStats _badgeStats = BadgeStats(
    nutritionStreak: 0,
    workoutStreak: 0,
    completeStreak: 0,
  );

  // Real daily stats
  double _todayCalories = 0;
  int _todayMinutes = 0;
  double _userWeightKg = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadUserRole();
    _loadCalendarActivity();
    _loadAiRecommendations();
    _loadDailyStats();
    _loadUserWeight();
    _loadBadges();
  }

  Future<void> _loadUserRole() async {
    final role = await TokenStorage.getUserRole();
    if (role != null) {
      if (mounted) setState(() => _userRole = role);
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.athleteId != widget.athleteId) {
      _loadCalendarActivity();
      _loadBadges();
      _loadDailyStats();
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
          // Compute today's workout minutes from today's sessions
          final todayKey = _formatDate(DateTime.now());
          _todayMinutes =
              workoutHistory.results
                  .where(
                    (s) =>
                        _formatDate((s.date as DateTime).toLocal()) == todayKey,
                  )
                  .length *
              45; // approx 45 min per session
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

  Future<void> _loadDailyStats() async {
    try {
      final today = _formatDate(DateTime.now());
      final meals = await _nutritionService.getMeals(
        date: today,
        athleteId: widget.athleteId,
      );
      if (mounted) {
        setState(() {
          _todayCalories = meals.fold<double>(0, (s, m) => s + m.calories);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserWeight() async {
    try {
      final res = await ApiClient.dio.get('users/profile/settings/');
      final data = res.data as Map<String, dynamic>;
      if (mounted && data['weight'] != null) {
        setState(() {
          _userWeightKg = double.tryParse(data['weight'].toString()) ?? 0.0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAiRecommendations() async {
    if (!mounted) return;
    setState(() => _isAiLoading = true);

    try {
      final response = await _recommendationRepository.fetchAIRecommendations();
      if (mounted) {
        debugPrint(
          "DEBUG: AI Recommendations loaded: ${response.recommendations.length}",
        );
        setState(() {
          _aiRecommendations = response.recommendations;
          _isAiLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ERROR fetching recommendations: $e");
      if (mounted) {
        setState(() {
          _aiRecommendations = []; // Clear to show empty state with count
          _isAiLoading = false;
        });
      }
    }
  }

  Future<void> _loadBadges() async {
    if (!mounted) return;
    setState(() => _isBadgeLoading = true);

    try {
      final results = await Future.wait([
        _badgeRepository.fetchAvailableBadges(),
        _badgeRepository.fetchUserBadgeSummary(),
      ]);

      final availableBadges = results[0] as List<BadgeDefinition>;
      final summary = results[1] as BadgeSummaryResponse;
      final unlockedIds = summary.unlockedBadges
          .map((item) => item.badge.id)
          .toSet();

      if (!mounted) return;

      setState(() {
        _availableBadges = availableBadges;
        _unlockedBadgeIds = unlockedIds;
        _userBadgeCount = summary.totalBadges;
        _badgeStats = summary.stats;
        _isBadgeLoading = false;
      });

      if (summary.newlyAwarded.isNotEmpty && mounted) {
        final names = summary.newlyAwarded
            .map((badge) => badge.name)
            .join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nuevo logro desbloqueado: $names'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableBadges = [];
          _unlockedBadgeIds = {};
          _userBadgeCount = 0;
          _badgeStats = BadgeStats(
            nutritionStreak: 0,
            workoutStreak: 0,
            completeStreak: 0,
          );
          _isBadgeLoading = false;
        });
      }
      debugPrint('ERROR fetching badges: $e');
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

  List<BadgeDefinition> get _previewBadges {
    const typeOrder = ['alimentacion', 'ejercicio', 'completa', 'logros'];
    final preview = <BadgeDefinition>[];

    for (final type in typeOrder) {
      final badge =
          _availableBadges.where((item) => item.badgeType == type).toList()
            ..sort((a, b) => a.level.compareTo(b.level));
      if (badge.isNotEmpty) {
        preview.add(badge.first);
      }
    }

    return preview;
  }

  bool _isBadgeUnlocked(BadgeDefinition badge) {
    if (_unlockedBadgeIds.contains(badge.id)) {
      return true;
    }

    switch (badge.badgeType) {
      case 'alimentacion':
        return _badgeStats.nutritionStreak >= badge.level;
      case 'ejercicio':
        return _badgeStats.workoutStreak >= badge.level;
      case 'completa':
        return _badgeStats.completeStreak >= badge.level;
      case 'logros':
        return _userBadgeCount >= badge.level;
      default:
        return false;
    }
  }

  Color _badgeAccentColor(String badgeType) {
    switch (badgeType) {
      case 'alimentacion':
        return const Color(0xFF22C55E);
      case 'ejercicio':
        return const Color(0xFFFF6B35);
      case 'completa':
        return const Color(0xFF06B6D4);
      case 'logros':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  String _badgeAssetPath(BadgeDefinition badge) {
    return 'assets/images/badges/svg/${badge.svgFilename}';
  }

  String _badgeProgressLabel(BadgeDefinition badge) {
    switch (badge.badgeType) {
      case 'alimentacion':
        return '${_badgeStats.nutritionStreak}/${badge.level} días';
      case 'ejercicio':
        return '${_badgeStats.workoutStreak}/${badge.level} días';
      case 'completa':
        return '${_badgeStats.completeStreak}/${badge.level} días';
      case 'logros':
        return '$_userBadgeCount/${badge.level} logros';
      default:
        return 'Disponible';
    }
  }

  Widget _buildBadgeSvg(BadgeDefinition badge, {double size = 74}) {
    final unlocked = _isBadgeUnlocked(badge);
    final assetPath = _badgeAssetPath(badge);

    return Opacity(
      opacity: unlocked ? 1 : 0.38,
      child: SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: unlocked
            ? null
            : const ColorFilter.matrix(<double>[
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
      ),
    );
  }

  Widget _buildBadgeCard(
    BadgeDefinition badge, {
    bool compact = false,
    VoidCallback? onTap,
  }) {
    final unlocked = _isBadgeUnlocked(badge);
    final accent = _badgeAccentColor(badge.badgeType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: compact ? 150 : null,
        padding: EdgeInsets.all(compact ? 14 : 18),
        decoration: BoxDecoration(
          gradient: unlocked
              ? LinearGradient(
                  colors: [accent.withValues(alpha: 0.12), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.96)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: AppRadius.card,
          border: Border.all(
            color: unlocked ? accent.withValues(alpha: 0.28) : AppColors.border,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: unlocked ? 0.14 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildBadgeSvg(badge, size: compact ? 62 : 78),
                ),
                const Spacer(),
                Icon(
                  unlocked ? Icons.verified_rounded : Icons.lock_rounded,
                  color: unlocked ? accent : AppColors.buttonDisabledText,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              badge.name,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.fitnessBold.copyWith(
                color: unlocked
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: compact ? 13 : 15,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.badgeTypeDisplay,
              style: TextStyle(
                color: unlocked ? accent : AppColors.buttonDisabledText,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _badgeProgressLabel(badge),
              style: TextStyle(
                color: unlocked
                    ? AppColors.textSecondary
                    : AppColors.buttonDisabledText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllBadgesSheet() {
    if (_availableBadges.isEmpty) return;

    final badges = List<BadgeDefinition>.from(_availableBadges)
      ..sort((a, b) {
        final typeCompare = a.badgeType.compareTo(b.badgeType);
        if (typeCompare != 0) return typeCompare;
        return a.level.compareTo(b.level);
      });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: AppColors.deepShadow,
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Todos los logros disponibles',
                      style: AppTextStyles.fitnessBold.copyWith(
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Se muestran en color los logros que ya cumpliste y en gris los bloqueados.',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: badges.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.86,
                          ),
                      itemBuilder: (context, index) {
                        final badge = badges[index];
                        return _buildBadgeCard(badge, onTap: null);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgesSection() {
    if (_isBadgeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableBadges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.whiteGlass,
          borderRadius: AppRadius.card,
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: const Text(
          'Todavía no hay logros configurados.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final previewBadges = _previewBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          '🏅 LOGROS Y DESAFÍOS',
          actionLabel: 'VER MÁS LOGROS',
          onAction: _showAllBadgesSheet,
        ),
        const SizedBox(height: 10),
        Text(
          'Vista previa de los 4 temas principales. Los logros en color ya están desbloqueados.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (previewBadges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.whiteGlass,
              borderRadius: AppRadius.card,
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Aún no se cargan badges de vista previa.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          SizedBox(
            height: 205,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: previewBadges.length,
              separatorBuilder: (_, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                return _buildBadgeCard(
                  previewBadges[index],
                  compact: true,
                  onTap: _showAllBadgesSheet,
                );
              },
            ),
          ),
      ],
    );
  }

  void _showExerciseDetailSheet(ExerciseRecommendation rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final controller = YoutubePlayerController(
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            mute: false,
            loop: false,
            enableJavaScript: true,
          ),
        );

        final videoId = rec.youtubeId.trim().isNotEmpty
            ? rec.youtubeId.trim()
            : 'gcNh17Ckjgg';
        controller.loadVideoById(videoId: videoId);

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D1E).withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: AppRadius.card,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.intensityNeon.withValues(
                                alpha: 0.1,
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: rec.youtubeId.isNotEmpty
                            ? YoutubePlayer(
                                controller: controller,
                                key: ValueKey(rec.youtubeId),
                              )
                            : _buildVideoPlaceholder(),
                      ),
                      const SizedBox(height: 12),
                      if (rec.muscle.isNotEmpty)
                        Wrap(spacing: 8, children: [_muscleBadge(rec.muscle)]),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _techMetric(
                              "SERIES",
                              "${rec.sets}",
                              Icons.refresh_rounded,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: _techMetric(
                              "REPS",
                              rec.reps,
                              Icons.fitness_center_rounded,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: _techMetric(
                              "DESC.",
                              "${rec.rest}s",
                              Icons.timer_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "GUÍA TÉCNICA DE ÉLITE",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _launchYouTube(rec.exerciseName),
                            icon: const Icon(
                              Icons.play_circle_fill,
                              color: Colors.red,
                              size: 18,
                            ),
                            label: const Text(
                              "TÉCNICA PRO",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        rec.instructions.isNotEmpty
                            ? rec.instructions
                            : "Ejecuta el movimiento con control total. Mantén la tensión en el músculo objetivo durante toda la fase.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.intensityNeon,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "¡LO TENGO!",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 140,
            child: Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_at6m8p.json', // Stable fitness animation
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              frameBuilder: (context, child, composition) {
                if (composition == null) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return child;
              },
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.fitness_center_rounded,
                size: 64,
                color: AppColors.intensityNeon.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "GUÍA VISUAL IA ACTIVA",
            style: TextStyle(
              color: AppColors.intensityNeon.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchYouTube(String query) async {
    final url = Uri.parse(
      'https://www.youtube.com/results?search_query=${Uri.encodeComponent("$query exercise technique")}',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir YouTube')),
        );
      }
    }
  }

  Widget _muscleBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _techMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.fitnessBold.copyWith(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
                  _buildSectionTitle("📊 ESTADÍSTICAS DEL DÍA"),
                  const SizedBox(height: 16),
                  _buildBentoGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("📅 CALENDARIO DE RACHA"),
                  const SizedBox(height: 16),
                  _buildStreakCalendar(),
                  if (_userRole != 'coach') ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle("🎯🌟 RECOMENDACIÓN DEL DÍA"),
                    const SizedBox(height: 16),
                    _buildAiRecommendations(),
                  ],
                  const SizedBox(height: 32),
                  _buildBadgesSection(),
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
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
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
                                      color: Colors.black.withValues(
                                        alpha: 0.8,
                                      ),
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
                                      color: Colors.black.withValues(
                                        alpha: 0.8,
                                      ),
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final hasAction = actionLabel != null && onAction != null;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.fitnessBold.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        if (hasAction)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }

  Widget _buildBentoGrid() {
    final streak = _currentStreakDays;

    return Column(
      children: [
        // ── Streak HERO (priority) ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6F00), Color(0xFFFFD740)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streak ${streak == 1 ? 'día' : 'días'} de racha',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        streak == 0
                            ? '¡Empieza hoy tu racha!'
                            : streak >= 7
                            ? '¡Increíble consistencia! 💪'
                            : '¡Sigue así, lo estás logrando!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Stats row ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _bentoItem(
                  title: 'CALORÍAS HOY',
                  value: _todayCalories > 0
                      ? _todayCalories.toStringAsFixed(0)
                      : '—',
                  unit: _todayCalories > 0 ? 'kcal' : '',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF5252),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bentoItem(
                  title: 'TIEMPO HOY',
                  value: _todayMinutes > 0 ? '$_todayMinutes' : '—',
                  unit: _todayMinutes > 0 ? 'min' : '',
                  icon: Icons.timer_rounded,
                  color: const Color(0xFF448AFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bentoItem(
                  title: 'PESO',
                  value: _userWeightKg > 0
                      ? _userWeightKg.toStringAsFixed(1)
                      : '—',
                  unit: _userWeightKg > 0 ? 'kg' : '',
                  icon: Icons.monitor_weight_rounded,
                  color: const Color(0xFF64FFDA),
                ),
              ),
            ],
          ),
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
                'Últimos 21 días',
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
                label: 'Alimentación',
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomLeft,
            child: Row(
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

  Widget _buildAiRecommendations() {
    if (_isAiLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_aiRecommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.whiteGlass,
          borderRadius: AppRadius.card,
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        ),
        child: Text(
          "No hay recomendaciones disponibles (Count: ${_aiRecommendations.length}).",
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _aiRecommendations.length,
        padding: const EdgeInsets.only(bottom: 8),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final rec = _aiRecommendations[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showExerciseDetailSheet(rec),
              borderRadius: AppRadius.card,
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D1E),
                  borderRadius: AppRadius.card,
                  border: Border.all(
                    color: AppColors.intensityNeon.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.intensityNeon.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                    ...AppColors.deepShadow,
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.03),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 40,
                      bottom: 40,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: AppColors.intensityNeon,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.psychology_rounded,
                                color: AppColors.intensityNeon,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "RECOMENDADO PARA TI",
                                style: AppTextStyles.fitnessCaption.copyWith(
                                  color: AppColors.intensityNeon,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            rec.exerciseName.toUpperCase(),
                            style: AppTextStyles.fitnessBold.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Text(
                              rec.reason,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "ANALIZADO POR IA",
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.arrow_circle_right_outlined,
                                color: AppColors.intensityNeon.withValues(
                                  alpha: 0.5,
                                ),
                                size: 24,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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
