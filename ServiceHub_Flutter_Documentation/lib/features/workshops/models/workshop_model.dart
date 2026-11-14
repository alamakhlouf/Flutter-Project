import '../../../design_system/app_colors.dart';

import 'package:flutter/material.dart';

enum WorkshopStatus { draft, published, cancelled, completed }

extension WorkshopStatusX on WorkshopStatus {
  String get label => switch (this) {
    WorkshopStatus.draft => 'DRAFT',
    WorkshopStatus.published => 'PUBLISHED',
    WorkshopStatus.cancelled => 'CANCELLED',
    WorkshopStatus.completed => 'COMPLETED',
  };

  Color get color => switch (this) {
    WorkshopStatus.draft => AppColors.warning,
    WorkshopStatus.published => AppColors.success,
    WorkshopStatus.cancelled => AppColors.error,
    WorkshopStatus.completed => AppColors.textSecondary,
  };

  static WorkshopStatus fromString(String? value) {
    return switch (value?.toUpperCase()) {
      'PUBLISHED' => WorkshopStatus.published,
      'CANCELLED' => WorkshopStatus.cancelled,
      'COMPLETED' => WorkshopStatus.completed,
      _ => WorkshopStatus.draft,
    };
  }
}

class WorkshopModel {
  const WorkshopModel({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    required this.title,
    required this.description,
    required this.category,
    required this.startDateTime,
    required this.endDateTime,
    required this.location,
    required this.capacity,
    required this.registrationDeadline,
    required this.status,
    required this.participantCount,
    this.coverImageUrl,
    this.workshopType = 'IN_PERSON',
    this.meetingUrl,
  });

  final String id;
  final String organizerId;
  final String organizerName;
  final String title;
  final String description;
  final String category;
  final String? coverImageUrl;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String location;
  final int capacity;
  final DateTime registrationDeadline;
  final WorkshopStatus status;
  final int participantCount;
  final String workshopType;
  final String? meetingUrl;

  bool get isOnline => workshopType.toUpperCase() == 'ONLINE';
  bool get isFull => participantCount >= capacity;
  bool get registrationClosed =>
      DateTime.now().isAfter(registrationDeadline) || isFull;

  factory WorkshopModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final organizerId = json['organizerId'];
    final start = DateTime.tryParse('${json['startDateTime']}');
    final end = DateTime.tryParse('${json['endDateTime']}');
    final deadline = DateTime.tryParse('${json['registrationDeadline']}');
    if (id == null ||
        organizerId == null ||
        start == null ||
        end == null ||
        deadline == null) {
      throw const FormatException('Incomplete workshop payload');
    }
    return WorkshopModel(
      id: id.toString(),
      organizerId: organizerId.toString(),
      organizerName: '${json['organizerName'] ?? 'Provider'}',
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? ''}',
      coverImageUrl: json['coverImageUrl']?.toString(),
      startDateTime: start,
      endDateTime: end,
      location: '${json['location'] ?? ''}',
      capacity: _int(json['capacity']),
      registrationDeadline: deadline,
      status: WorkshopStatusX.fromString(json['status']?.toString()),
      participantCount: _int(json['participantCount']),
      workshopType: '${json['workshopType'] ?? 'IN_PERSON'}',
      meetingUrl: json['meetingUrl']?.toString(),
    );
  }

  static int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

class WorkshopRegistration {
  const WorkshopRegistration({
    required this.id,
    required this.workshopId,
    required this.participantId,
    required this.status,
    required this.registeredAt,
    this.cancelledAt,
    this.workshopTitle,
    this.workshopLocation,
    this.workshopStartDateTime,
    this.workshopStatus,
    this.organizerName,
    this.meetingUrl,
    this.workshopType,
  });

  final String id;
  final String workshopId;
  final String participantId;
  final String status;
  final DateTime registeredAt;
  final DateTime? cancelledAt;
  final String? workshopTitle;
  final String? workshopLocation;
  final DateTime? workshopStartDateTime;
  final String? workshopStatus;
  final String? organizerName;
  final String? meetingUrl;
  final String? workshopType;

  bool get isActive => status == 'REGISTERED';
  bool get isOnline => workshopType?.toUpperCase() == 'ONLINE';

  factory WorkshopRegistration.fromJson(Map<String, dynamic> json) {
    final registeredAt = DateTime.tryParse('${json['registeredAt']}');
    if (json['id'] == null ||
        json['workshopId'] == null ||
        json['participantId'] == null ||
        registeredAt == null) {
      throw const FormatException('Incomplete registration payload');
    }
    return WorkshopRegistration(
      id: '${json['id']}',
      workshopId: '${json['workshopId']}',
      participantId: '${json['participantId']}',
      status: '${json['status'] ?? 'CANCELLED'}',
      registeredAt: registeredAt,
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.tryParse('${json['cancelledAt']}'),
      workshopTitle: json['workshopTitle']?.toString(),
      workshopLocation: json['workshopLocation']?.toString(),
      workshopStartDateTime: json['workshopStartDateTime'] == null
          ? null
          : DateTime.tryParse('${json['workshopStartDateTime']}'),
      workshopStatus: json['workshopStatus']?.toString(),
      organizerName: json['organizerName']?.toString(),
      meetingUrl: json['workshopMeetingUrl']?.toString() ?? json['meetingUrl']?.toString(),
      workshopType: json['workshopType']?.toString(),
    );
  }
}
