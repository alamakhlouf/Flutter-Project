import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';

enum InventoryStatus { inStock, lowStock, outOfStock }

extension InventoryStatusX on InventoryStatus {
  String get label => switch (this) {
    InventoryStatus.inStock => 'IN_STOCK',
    InventoryStatus.lowStock => 'LOW_STOCK',
    InventoryStatus.outOfStock => 'OUT_OF_STOCK',
  };

  Color get color => switch (this) {
    InventoryStatus.inStock => AppColors.success,
    InventoryStatus.lowStock => AppColors.warning,
    InventoryStatus.outOfStock => AppColors.error,
  };
}

class InventoryItemModel {
  const InventoryItemModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    this.imageUrl,
    this.catalogCategory,
    this.catalogPrice,
    this.lowStockThreshold,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String providerId;
  final String name;
  final String description;
  final int quantity;
  final String unit;
  final String? imageUrl;
  final String? catalogCategory;
  final double? catalogPrice;
  final int? lowStockThreshold;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryStatus get status {
    if (quantity <= 0) {
      return InventoryStatus.outOfStock;
    }
    if (lowStockThreshold != null && quantity <= lowStockThreshold!) {
      return InventoryStatus.lowStock;
    }
    return InventoryStatus.inStock;
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final providerId = json['providerId'];
    final name = json['name'];
    final description = json['description'];
    final quantityRaw = json['quantity'];
    final unit = json['unit'];

    if (id == null ||
        id.toString().isEmpty ||
        providerId == null ||
        providerId.toString().isEmpty ||
        name is! String ||
        description is! String ||
        unit is! String) {
      throw const FormatException('Incomplete inventory payload');
    }

    final quantity = _asInt(quantityRaw, fallback: 0);
    final thresholdRaw = json['lowStockThreshold'];
    final lowStockThreshold = thresholdRaw == null
        ? null
        : _asInt(thresholdRaw, fallback: null);

    final createdAtRaw = json['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    final updatedAtRaw = json['updatedAt'];
    DateTime? updatedAt;
    if (updatedAtRaw is String) {
      updatedAt = DateTime.tryParse(updatedAtRaw);
    }

    return InventoryItemModel(
      id: id.toString(),
      providerId: providerId.toString(),
      name: name,
      description: description,
      quantity: quantity,
      unit: unit,
      imageUrl: _optionalString(json['imageUrl']),
      catalogCategory: _optionalString(json['catalogCategory']),
      catalogPrice: _optionalDouble(json['catalogPrice']),
      lowStockThreshold: lowStockThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (catalogCategory != null) 'catalogCategory': catalogCategory,
      if (catalogPrice != null) 'catalogPrice': catalogPrice,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  InventoryItemModel copyWith({
    String? id,
    String? providerId,
    String? name,
    String? description,
    int? quantity,
    String? unit,
    String? imageUrl,
    String? catalogCategory,
    double? catalogPrice,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      catalogCategory: catalogCategory ?? this.catalogCategory,
      catalogPrice: catalogPrice ?? this.catalogPrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _asInt(Object? value, {int? fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      if (fallback != null) return fallback;
      throw const FormatException('Invalid integer value');
    }
    if (fallback != null) return fallback;
    throw const FormatException('Missing integer value');
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    throw const FormatException('Unexpected inventory image field');
  }

  static double? _optionalDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw const FormatException('Unexpected inventory price field');
  }
}
