import 'package:flutter/material.dart';

enum NotificationType { routineAssigned, routineUpdated, community, system }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  bool isRead;
  final NotificationType type;
  final String? relatedId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    required this.type,
    this.relatedId,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.routineAssigned:
        return Icons.star_rounded;
      case NotificationType.routineUpdated:
        return Icons.update_rounded;
      case NotificationType.community:
        return Icons.people_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.routineAssigned:
        return Colors.amber;
      case NotificationType.routineUpdated:
        return Colors.blue;
      case NotificationType.community:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
