import 'package:flutter/material.dart';

enum NotificationType {
  bookingReminder,
  bookingCancelled,
  reward,
  general,
  tournamentReminder,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.icon,
    required this.color,
    this.isUnread = true,
    this.bookingId,
    this.tournamentId,
    this.type = NotificationType.general,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final bool isUnread;
  final String? bookingId;
  final String? tournamentId;
  final NotificationType type;

  AppNotification markRead() => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        icon: icon,
        color: color,
        isUnread: false,
        bookingId: bookingId,
        tournamentId: tournamentId,
        type: type,
      );

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
  }
}
