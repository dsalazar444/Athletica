import 'package:flutter/material.dart';
import '../../models/notification/notification_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../routine/routine_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final List<NotificationModel> notifications;
  final VoidCallback onClearAll;

  const NotificationsScreen({
    super.key,
    required this.notifications,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NOTIFICACIONES', style: AppTextStyles.fitnessBold),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: onClearAll,
              child: const Text('Limpiar Todo', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: AppColors.textHint.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'NO TIENES NOTIFICACIONES',
            style: AppTextStyles.fitnessBold.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          const Text(
            'Te avisaremos cuando haya novedades en tu plan.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(context, notification),
          borderRadius: AppRadius.card,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notification.icon, color: notification.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.title.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                          ),
                          Text(
                            _formatTime(notification.date),
                            style: TextStyle(color: AppColors.textHint, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    if (notification.type == NotificationType.routineAssigned || notification.type == NotificationType.routineUpdated) {
      if (notification.relatedId != null) {
        final routineId = int.tryParse(notification.relatedId!);
        if (routineId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoutineDetailScreenFromId(routineId: routineId),
            ),
          );
        }
      }
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }
}
