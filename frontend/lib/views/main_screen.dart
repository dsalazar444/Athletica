import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'routine/routines_list_screen.dart';
import 'profile/profile_screen.dart';
import 'nutrition/nutrition_screen.dart';
import 'nutrition/nutrition_plans_screen.dart';
import 'coach/coach_athletes_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../core/token_storage.dart';
import '../../core/api_client.dart';
import 'notifications/notifications_screen.dart';
import '../../models/notification/notification_model.dart';
import '../../models/notification/reminder_model.dart';
import '../../repositories/notification/reminder_service.dart';
import 'community/athlete_community_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _homeRefreshTick = 0;
  int _profileRefreshTick = 0;
  int? _athleteId;
  String? _userRole;
  Timer? _pollingTimer;
  Timer? _reminderPollingTimer;
  OverlayEntry? _activeBannerEntry;
  final List<NotificationModel> _notifications = [];
  final ReminderService _reminderService = ReminderService();

  final GlobalKey<RoutinesListScreenState> _routinesKey = GlobalKey();
  final GlobalKey<CoachAthletesScreenState> _coachAthletesKey = GlobalKey();
  final GlobalKey<CommunityScreenState> _communityKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final athleteId = await TokenStorage.getAthleteId();
    final userId = await TokenStorage.getUserId();
    final role = await TokenStorage.getUserRole();
    final savedNotifications = await TokenStorage.getNotifications();
    if (mounted) {
      setState(() {
        // Nutrition needs the Profile ID (athleteId). Coaches might use userId for now if they have no profile.
        _athleteId = (role == 'athlete') ? athleteId : userId;
        _userRole = role;
        _notifications
          ..clear()
          ..addAll(savedNotifications);
      });

      await _syncNotifiedRemindersToNotifications();

      // Check routine updates using the USER ID (since assigned_athletes are users)
      if (userId != null) {
        if (role == 'athlete') {
          _checkRoutineUpdate(userId);
        }
        _checkNewFollowers();

        // Start polling every 5 minutes (single timer for all checks)
        _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
          if (role == 'athlete') {
            _checkRoutineUpdate(userId);
          }
          _checkNewFollowers();
        });
      }

      await _startReminderPollingWhenReady();
    }
  }

  Future<void> _startReminderPollingWhenReady() async {
    if (_reminderPollingTimer != null) {
      return;
    }

    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null) {
      return;
    }

    _startReminderPolling();
  }

  void _startReminderPolling() {
    if (_reminderPollingTimer != null) {
      return;
    }
    _checkDueReminders();
    _reminderPollingTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkDueReminders(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reminderPollingTimer?.cancel();
    _activeBannerEntry?.remove();
    super.dispose();
  }

  Future<void> _checkDueReminders() async {
    try {
      final dueReminders = await _reminderService.getDueReminders();
      // Debug: print when received
      try {
        // ignore: avoid_print
        print(
          'MainScreen._checkDueReminders -> received ${dueReminders.length} due reminders',
        );
      } catch (_) {}
      if (!mounted || dueReminders.isEmpty) return;

      final List<NotificationModel> newReminderNotifications = [];
      for (final reminder in dueReminders) {
        final alreadyExists = _notifications.any(
          (n) =>
              n.type == NotificationType.reminder &&
              n.relatedId == reminder.id.toString(),
        );
        if (alreadyExists) {
          continue;
        }

        newReminderNotifications.add(_buildReminderNotification(reminder));
      }

      if (newReminderNotifications.isEmpty) return;

      setState(() {
        _notifications.insertAll(0, newReminderNotifications);
      });

      await TokenStorage.saveNotifications(_notifications);

      // Show a visible in-app popup for the newest reminder.
      _showTopNotificationBanner(
        newReminderNotifications.first.title,
        onAction: _openNotificationsScreen,
      );

      await _syncNotifiedRemindersToNotifications();
    } catch (e) {
      debugPrint('Error checking due reminders (Silent): $e');
    }
  }

  Future<void> _syncNotifiedRemindersToNotifications() async {
    try {
      final reminders = await _reminderService.getReminders();
      final notifiedReminders = reminders.where(
        (reminder) => reminder.notifiedAt != null,
      );
      if (notifiedReminders.isEmpty || !mounted) {
        return;
      }

      final shownIds = await TokenStorage.getShownReminderIds();

      final List<NotificationModel> newNotifications = [];
      for (final reminder in notifiedReminders) {
        // Skip if already shown/deleted by user
        if (shownIds.contains(reminder.id)) {
          continue;
        }

        final alreadyExists = _notifications.any(
          (notification) =>
              notification.type == NotificationType.reminder &&
              notification.relatedId == reminder.id.toString(),
        );
        if (alreadyExists) {
          continue;
        }

        newNotifications.add(
          _buildReminderNotification(
            reminder,
            date: reminder.notifiedAt ?? reminder.remindAt,
          ),
        );
      }

      if (newNotifications.isEmpty) {
        return;
      }

      setState(() {
        _notifications.insertAll(0, newNotifications);
      });

      await TokenStorage.saveNotifications(_notifications);
    } catch (e) {
      debugPrint('Error syncing notified reminders (Silent): $e');
    }
  }

  String _reminderTitle(ReminderModel reminder) {
    switch (reminder.activityType) {
      case 'training':
        return 'Entrenamiento';
      case 'nutrition':
        return 'Alimentación';
      default:
        return 'Recordatorio';
    }
  }

  String _reminderMessage(ReminderModel reminder) {
    switch (reminder.activityType) {
      case 'training':
        return 'Recuerda realizar tu entrenamiento de hoy.';
      case 'nutrition':
        return 'Recuerda registrar tus comidas del día de hoy.';
      default:
        return 'Tienes un recordatorio pendiente para hoy.';
    }
  }

  NotificationModel _buildReminderNotification(
    ReminderModel reminder, {
    DateTime? date,
  }) {
    return NotificationModel(
      id: 'reminder-${reminder.id}',
      title: _reminderTitle(reminder),
      message: _reminderMessage(reminder),
      date: date ?? DateTime.now(),
      type: NotificationType.reminder,
      relatedId: reminder.id.toString(),
    );
  }

  Future<void> _checkRoutineUpdate(int userId) async {
    try {
      final response = await ApiClient.dio.get(
        'routines/athlete/$userId/active/',
      );
      final int? currentRoutineId = response.data['id'];
      final int? lastRoutineId = await TokenStorage.getLastRoutineId();

      if (currentRoutineId != null) {
        if (currentRoutineId != lastRoutineId && mounted) {
          final isFirstTime = lastRoutineId == null;
          final title = isFirstTime
              ? 'Nueva Rutina Asignada'
              : 'Rutina Actualizada';
          final message = isFirstTime
              ? 'Tu entrenador te ha asignado un nuevo plan de entrenamiento.'
              : 'Se han realizado cambios en tu rutina actual.';

          final shouldInsert =
              _notifications.isEmpty ||
              !(_notifications.first.title == title &&
                  _notifications.first.message == message);

          if (shouldInsert) {
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

            await TokenStorage.saveNotifications(_notifications);
            _showTopNotificationBanner(
              title,
              onAction: () => setState(() => _currentIndex = 1),
            );
          }
        }

        await TokenStorage.saveLastRoutineId(currentRoutineId);
      }
    } catch (e) {
      debugPrint('Error checking routine update (Silent): $e');
    }
  }

  void _showTopNotificationBanner(
    String message, {
    required VoidCallback onAction,
  }) {
    _activeBannerEntry?.remove();

    final overlay = Overlay.of(context, rootOverlay: true);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top + 12;
        return Positioned(
          left: 16,
          right: 16,
          top: topPadding,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      entry.remove();
                      _activeBannerEntry = null;
                      onAction();
                    },
                    child: const Text(
                      'VER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      entry.remove();
                      _activeBannerEntry = null;
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _activeBannerEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 5), () {
      if (_activeBannerEntry == entry) {
        entry.remove();
        _activeBannerEntry = null;
      }
    });
  }

  void _openNotificationsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          notifications: _notifications,
          onClearAll: () {
            setState(() => _notifications.clear());
            TokenStorage.clearNotifications();
          },
          onDeleteNotification: (notificationId) {
            final notification = _notifications.firstWhere(
              (n) => n.id == notificationId,
              orElse: () => NotificationModel(
                id: notificationId,
                title: '',
                message: '',
                date: DateTime.now(),
                type: NotificationType.system,
              ),
            );
            setState(() {
              _notifications.removeWhere(
                (notification) => notification.id == notificationId,
              );
            });
            TokenStorage.saveNotifications(_notifications);
            if (notification.type == NotificationType.reminder &&
                notification.relatedId != null) {
              final reminderId = int.tryParse(notification.relatedId!);
              if (reminderId != null) {
                TokenStorage.addShownReminderId(reminderId);
              }
            }
          },
        ),
      ),
    ).then((_) async {
      setState(() {
        for (var n in _notifications) {
          n.isRead = true;
        }
      });
      await TokenStorage.saveNotifications(_notifications);
    });
  }

  Future<void> _checkNewFollowers() async {
    try {
      final String endpoint = _userRole == 'coach'
          ? 'dashboard/coach/'
          : 'dashboard/athlete/';

      final response = await ApiClient.dio.get(endpoint);
      final int currentFollowersCount = response.data['followers_count'] ?? 0;
      final int? lastFollowersCount =
          await TokenStorage.getLastFollowersCount();

      if (lastFollowersCount != null &&
          currentFollowersCount > lastFollowersCount) {
        final newFollowersCount = currentFollowersCount - lastFollowersCount;

        if (mounted) {
          final title = 'Nuevos Seguidores';
          final message = newFollowersCount == 1
              ? 'Un usuario empezó a seguirte'
              : '$newFollowersCount usuarios empezaron a seguirte';

          final shouldInsert =
              _notifications.isEmpty ||
              !(_notifications.first.title == title &&
                  _notifications.first.message == message);

          if (shouldInsert) {
            setState(() {
              _notifications.insert(
                0,
                NotificationModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  message: message,
                  date: DateTime.now(),
                  type: NotificationType.followerAdded,
                ),
              );
            });

            _showNotificationSnackBar(title, 4);
          }
        }
      } else if (lastFollowersCount == null && currentFollowersCount > 0) {
        if (mounted) {
          final title = 'Tienes nuevos seguidores';
          final message = currentFollowersCount == 1
              ? 'Tienes 1 seguidor'
              : 'Tienes $currentFollowersCount seguidores';

          final shouldInsert =
              _notifications.isEmpty ||
              !(_notifications.first.title == title &&
                  _notifications.first.message == message);

          if (shouldInsert) {
            setState(() {
              _notifications.insert(
                0,
                NotificationModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  message: message,
                  date: DateTime.now(),
                  type: NotificationType.followerAdded,
                ),
              );
            });

            _showNotificationSnackBar(title, 4);
          }
        }
      }

      await TokenStorage.saveLastFollowersCount(currentFollowersCount);
    } catch (e) {
      debugPrint('Error checking new followers (Silent): $e');
    }
  }

  void _showNotificationSnackBar(String message, int indexPage) {
    final controller = ScaffoldMessenger.of(context).showSnackBar(
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
          label: 'VER',
          textColor: Colors.white,
          onPressed: () => setState(() => _currentIndex = indexPage),
        ),
      ),
    );

    controller.closed.then((_) async {
      setState(() {
        for (var n in _notifications) {
          n.isRead = true;
        }
      });
      await TokenStorage.saveNotifications(_notifications);
    });
  }

  // Índices fijos — la lista siempre tiene 6 elementos
  static const int _athletesIndex = 3;
  static const int _communityIndex = 4;
  static const int _profileIndex = 5;

  List<Widget> get _screens => [
    HomeScreen(
      hasNotification: _notifications.any((n) => !n.isRead),
      athleteId: _athleteId,
      refreshTick: _homeRefreshTick,
      onNotificationTap: _openNotificationsScreen,
    ),
    RoutinesListScreen(key: _routinesKey),
    _buildNutritionScreen(),
    CoachAthletesScreen(key: _coachAthletesKey),
    CommunityScreen(key: _communityKey, mineOnly: _userRole == 'coach'),
    ProfileScreen(
      onReminderSaved: _checkDueReminders,
      refreshTick: _profileRefreshTick,
    ),
  ];

  Widget _buildNutritionScreen() {
    if (_userRole == 'coach') {
      return const NutritionPlansScreen();
    }
    final id = _athleteId;
    if (id != null) {
      return NutritionScreen(athleteId: id);
    }
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
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
            color: Colors.white.withValues(alpha: 0.95),
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
              if (_userRole == 'coach')
                _navItem(_athletesIndex, Icons.people_alt_rounded, 'Atletas'),
              _navItem(_communityIndex, Icons.public_rounded, 'Comunidad'),
              _navItem(_profileIndex, Icons.person_rounded, 'Perfil'),
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
          setState(() {
            _currentIndex = index;
            if (index == 0) {
              _homeRefreshTick++;
            }
            if (index == _profileIndex) {
              _profileRefreshTick++;
            }
          });
          if (index == 1) {
            _routinesKey.currentState?.refresh();
          } else if (index == _athletesIndex) {
            _coachAthletesKey.currentState?.refresh();
          } else if (index == _communityIndex) {
            _communityKey.currentState?.refresh();
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
