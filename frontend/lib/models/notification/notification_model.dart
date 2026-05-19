import 'package:flutter/material.dart';

enum NotificationType {
  routineAssigned,
  routineUpdated,
  reminder,
  community,
  followerAdded,
  system,
}

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
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.community:
        return Icons.people_rounded;
      case NotificationType.followerAdded:
        return Icons.person_add_rounded;
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
      case NotificationType.reminder:
        return Colors.deepOrange;
      case NotificationType.community:
        return Colors.green;
      case NotificationType.followerAdded:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      date: DateTime.parse(json['date']).toLocal(),
      isRead: json['isRead'] ?? false,
      type: NotificationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      relatedId: json['relatedId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'isRead': isRead,
      'type': type.name,
      'relatedId': relatedId,
    };
  }
}
