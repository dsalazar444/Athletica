import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'routine/routines_list_screen.dart';
import 'profile/profile_screen.dart';
import 'nutrition/nutrition_screen.dart';
import 'coach/coach_athletes_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../core/token_storage.dart';
import '../../core/api_client.dart';
import 'notifications/notifications_screen.dart';
import '../../models/notification/notification_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int? _athleteId;
  String? _userRole;
  Timer? _pollingTimer;
  final List<NotificationModel> _notifications = [];

  final GlobalKey<RoutinesListScreenState> _routinesKey = GlobalKey();
  final GlobalKey<CoachAthletesScreenState> _coachAthletesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final athleteId = await TokenStorage.getAthleteId();
    final userId = await TokenStorage.getUserId();
    final role = await TokenStorage.getUserRole();
    if (mounted) {
      setState(() {
        // Nutrition needs the Profile ID (athleteId). Coaches might use userId for now if they have no profile.
        _athleteId = (role == 'athlete') ? athleteId : userId;
        _userRole = role;
      });
      // Check routine updates using the USER ID (since assigned_athletes are users)
      if (role == 'athlete' && userId != null) {
        _checkRoutineUpdate(userId);
        // Start polling every 5 minutes
        _pollingTimer = Timer.periodic(
          const Duration(minutes: 5),
          (_) => _checkRoutineUpdate(userId),
        );
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkRoutineUpdate(int userId) async {
    try {
      final response = await ApiClient.dio.get(
        'routines/athlete/$userId/active/',
      );
      final int? currentRoutineId = response.data['id'];
      final int? lastRoutineId = await TokenStorage.getLastRoutineId();

      if (currentRoutineId != null) {
        // Notificar si hay una rutina nueva (incluyendo la primera asignación)
        if (currentRoutineId != lastRoutineId) {
          if (mounted) {
            final isFirstTime = lastRoutineId == null;
            final title = isFirstTime
                ? "Nueva Rutina Asignada"
                : "Rutina Actualizada";
            final message = isFirstTime
                ? "Tu entrenador te ha asignado un nuevo plan de entrenamiento."
                : "Se han realizado cambios en tu rutina actual.";

            setState(() {
              _notifications.insert(
                0,
                NotificationModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  message: message,
                  date: DateTime.now(),
                  type: isFirstTime
                      ? NotificationType.routineAssigned
                      : NotificationType.routineUpdated,
                  relatedId: currentRoutineId.toString(),
                ),
              );
            });

            _showNotificationSnackBar(title);
          }
        }
        await TokenStorage.saveLastRoutineId(currentRoutineId);
      }
    } catch (e) {
      debugPrint("Error checking routine update (Silent): $e");
    }
  }

  void _showNotificationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: "VER",
          textColor: Colors.white,
          onPressed: () => setState(() => _currentIndex = 1), // Ir a rutinas
        ),
      ),
    );
  }

  List<Widget> get _screens => [
    HomeScreen(
      hasNotification: _notifications.any((n) => !n.isRead),
      onNotificationTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationsScreen(
              notifications: _notifications,
              onClearAll: () => setState(() => _notifications.clear()),
            ),
          ),
        ).then((_) {
          // Mark all as read after viewing
          setState(() {
            for (var n in _notifications) {
              n.isRead = true;
            }
          });
        });
      },
    ),
    RoutinesListScreen(key: _routinesKey),
    _buildNutritionScreen(),
    _buildCommunityOrAthletesScreen(),
    const ProfileScreen(),
  ];

  Widget _buildNutritionScreen() {
    // Coaches can also access nutrition with their own user ID
    final id = _athleteId;
    if (id != null) {
      return NutritionScreen(athleteId: id);
    }
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Cargando perfil...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityOrAthletesScreen() {
    if (_userRole == 'coach') {
      return CoachAthletesScreen(key: _coachAthletesKey);
    }
    return const Center(child: Text('Comunidad'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return ClipRRect(
      borderRadius: AppRadius.cardLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95), // Lighter elegant pill
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.grid_view_rounded, 'Inicio'),
              _navItem(1, Icons.fitness_center_rounded, 'Rutinas'),
              _navItem(2, Icons.restaurant_rounded, 'Comida'),
              _navItem(
                3,
                Icons.people_alt_rounded,
                _userRole == 'coach' ? 'Atletas' : 'Comunidad',
              ),
              _navItem(4, Icons.person_rounded, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (_currentIndex != index) {
          setState(() => _currentIndex = index);
          // Refresh logic when switching tabs
          if (index == 1) {
            _routinesKey.currentState?.refresh();
          } else if (index == 3 && _userRole == 'coach') {
            _coachAthletesKey.currentState?.refresh();
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondary.withValues(alpha: 0.6),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
