import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool read;
  final DateTime createdAt;

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: '${json['id']}',
      title: '${json['title'] ?? ''}',
      message: '${json['message'] ?? ''}',
      type: '${json['type'] ?? 'GENERAL'}',
      relatedEntityType: json['relatedEntityType']?.toString(),
      relatedEntityId: json['relatedEntityId']?.toString(),
      read: json['read'] == true,
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    );
  }

  IconData get icon => switch (type.toUpperCase()) {
        'BOOKING' => Icons.calendar_month_rounded,
        'ORDER' => Icons.shopping_bag_outlined,
        'WORKSHOP' => Icons.school_outlined,
        'INVENTORY' => Icons.inventory_2_outlined,
        'REVIEW' => Icons.star_outline_rounded,
        'REPORT' => Icons.outlined_flag_rounded,
        _ => Icons.notifications_none_rounded,
      };

  Color get iconColor => switch (type.toUpperCase()) {
        'BOOKING' => AppColors.primary,
        'ORDER' => AppColors.secondary,
        'WORKSHOP' => AppColors.tertiary,
        'INVENTORY' => AppColors.warning,
        'REVIEW' => AppColors.warning,
        'REPORT' => AppColors.error,
        _ => AppColors.primary,
      };
}
