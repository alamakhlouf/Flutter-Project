import 'package:flutter/material.dart';
import '../../../design_system/app_colors.dart';

enum BookingStatus {
  pending,
  accepted,
  rejected,
  inProgress,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
    BookingStatus.pending => 'PENDING',
    BookingStatus.accepted => 'ACCEPTED',
    BookingStatus.rejected => 'REJECTED',
    BookingStatus.inProgress => 'IN_PROGRESS',
    BookingStatus.completed => 'COMPLETED',
    BookingStatus.cancelled => 'CANCELLED',
  };

  Color get color => switch (this) {
    BookingStatus.pending => AppColors.warning,
    BookingStatus.accepted => AppColors.info,
    BookingStatus.rejected => AppColors.error,
    BookingStatus.inProgress => AppColors.primary,
    BookingStatus.completed => AppColors.success,
    BookingStatus.cancelled => AppColors.textSecondary,
  };

  static BookingStatus fromString(String? value) {
    if (value == null) return BookingStatus.pending;
    switch (value.toUpperCase()) {
      case 'ACCEPTED':
        return BookingStatus.accepted;
      case 'REJECTED':
        return BookingStatus.rejected;
      case 'IN_PROGRESS':
        return BookingStatus.inProgress;
      case 'COMPLETED':
        return BookingStatus.completed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'PENDING':
      default:
        return BookingStatus.pending;
    }
  }
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.serviceId,
    required this.serviceTitle,
    required this.price,
    required this.description,
    required this.preferredDateTime,
    required this.status,
    this.createdAt,
    this.customerName,
    this.customerEmail,
  });

  final String id;
  final String customerId;
  final String providerId;
  final String serviceId;
  final String serviceTitle;
  final double price;
  final String description;
  final DateTime preferredDateTime;
  final BookingStatus status;
  final DateTime? createdAt;
  final String? customerName;
  final String? customerEmail;

  bool get isTerminal =>
      status == BookingStatus.rejected ||
      status == BookingStatus.cancelled ||
      status == BookingStatus.completed;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final customerId = json['customerId'];
    final providerId = json['providerId'];
    final serviceId = json['serviceId'];
    final serviceTitle = json['serviceTitle'] ?? json['serviceTitleSnapshot'] ?? 'Service';
    final priceRaw = json['price'] ?? json['priceSnapshot'];
    final description = json['description'] ?? '';
    final preferredRaw = json['preferredDateTime'];
    final statusRaw = json['status'];

    if (id == null || customerId == null || providerId == null || serviceId == null) {
      throw const FormatException('Incomplete booking payload');
    }

    double price = 0.0;
    if (priceRaw is num) {
      price = priceRaw.toDouble();
    } else if (priceRaw is String && priceRaw.isNotEmpty) {
      price = double.tryParse(priceRaw) ?? 0.0;
    }

    DateTime preferredDateTime = DateTime.now();
    if (preferredRaw is String) {
      preferredDateTime = DateTime.tryParse(preferredRaw) ?? DateTime.now();
    } else if (preferredRaw is int) {
      preferredDateTime = DateTime.fromMillisecondsSinceEpoch(preferredRaw);
    }

    DateTime? createdAt;
    final createdRaw = json['createdAt'];
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    }

    return BookingModel(
      id: id.toString(),
      customerId: customerId.toString(),
      providerId: providerId.toString(),
      serviceId: serviceId.toString(),
      serviceTitle: serviceTitle.toString(),
      price: price,
      description: description.toString(),
      preferredDateTime: preferredDateTime,
      status: BookingStatusX.fromString(statusRaw?.toString()),
      createdAt: createdAt,
      customerName: json['customerName']?.toString(),
      customerEmail: json['customerEmail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'providerId': providerId,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'price': price,
      'description': description,
      'preferredDateTime': preferredDateTime.toIso8601String(),
      'status': status.label,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (customerName != null) 'customerName': customerName,
      if (customerEmail != null) 'customerEmail': customerEmail,
    };
  }
}
