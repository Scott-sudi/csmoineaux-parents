import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'home_models.dart';

/// Élément de l'inbox Notifications (finance / secrétariat / discipline).
class ParentNotificationItem extends Equatable {
  const ParentNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestampLabel,
    required this.type,
    this.body = '',
    this.isRead = true,
    this.studentId = '',
    this.studentName = '',
    this.source = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String timestampLabel;
  final ActivityType type;
  final String body;
  final bool isRead;
  final String studentId;
  final String studentName;
  final String source;

  /// Filtre maquette : toutes / generales / scolaires / financieres.
  String get filterBucket {
    switch (source) {
      case 'finance_payment':
        return 'financieres';
      case 'discipline_summons':
      case 'discipline_incident':
        return 'scolaires';
      case 'secretariat_communication':
        return type == ActivityType.bulletin ? 'scolaires' : 'generales';
      default:
        if (type == ActivityType.fees) return 'financieres';
        if (type == ActivityType.meeting || type == ActivityType.bulletin) {
          return 'scolaires';
        }
        return 'generales';
    }
  }

  Color get iconBackground {
    switch (type) {
      case ActivityType.bulletin:
        return AppColors.activityBulletin;
      case ActivityType.meeting:
        return AppColors.activityMeeting;
      case ActivityType.fees:
        return AppColors.activityFees;
      case ActivityType.info:
        return source.startsWith('discipline')
            ? const Color(0xFFC62828)
            : AppColors.primaryLight;
    }
  }

  IconData get icon {
    switch (source) {
      case 'finance_payment':
        return Icons.check_circle_outline;
      case 'discipline_summons':
        return Icons.campaign_outlined;
      case 'discipline_incident':
        return Icons.warning_amber_rounded;
      case 'secretariat_communication':
        return type == ActivityType.bulletin
            ? Icons.description_outlined
            : Icons.info_outline;
      default:
        switch (type) {
          case ActivityType.bulletin:
            return Icons.description_outlined;
          case ActivityType.meeting:
            return Icons.campaign_outlined;
          case ActivityType.fees:
            return Icons.check_circle_outline;
          case ActivityType.info:
            return Icons.info_outline;
        }
    }
  }

  RecentActivity get asActivity => RecentActivity(
        id: id,
        title: title,
        subtitle: subtitle,
        timestampLabel: timestampLabel,
        type: type,
      );

  factory ParentNotificationItem.fromJson(Map<String, dynamic> json) {
    return ParentNotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      timestampLabel: json['timestamp_label']?.toString() ?? '',
      type: RecentActivity.fromJson({
        'id': json['id'],
        'title': json['title'],
        'subtitle': json['subtitle'],
        'timestamp_label': json['timestamp_label'],
        'type': json['type'],
      }).type,
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? true,
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, title, isRead, type];
}

class ParentNotificationsResult extends Equatable {
  const ParentNotificationsResult({
    required this.items,
    this.unreadCount = 0,
    this.totalCount = 0,
  });

  final List<ParentNotificationItem> items;
  final int unreadCount;
  final int totalCount;

  factory ParentNotificationsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return ParentNotificationsResult(
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
      totalCount: int.tryParse(json['total_count']?.toString() ?? '') ?? 0,
      items: raw
          .map(
            (e) => ParentNotificationItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [items, unreadCount, totalCount];
}
