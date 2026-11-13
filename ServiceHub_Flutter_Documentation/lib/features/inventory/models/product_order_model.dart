enum ProductOrderStatus {
  pending,
  accepted,
  rejected,
  processing,
  completed,
  cancelled,
}

extension ProductOrderStatusX on ProductOrderStatus {
  String get label => switch (this) {
    ProductOrderStatus.pending => 'PENDING',
    ProductOrderStatus.accepted => 'ACCEPTED',
    ProductOrderStatus.rejected => 'REJECTED',
    ProductOrderStatus.processing => 'PROCESSING',
    ProductOrderStatus.completed => 'COMPLETED',
    ProductOrderStatus.cancelled => 'CANCELLED',
  };

  static ProductOrderStatus fromString(String? value) =>
      switch (value?.toUpperCase()) {
        'ACCEPTED' => ProductOrderStatus.accepted,
        'REJECTED' => ProductOrderStatus.rejected,
        'PROCESSING' => ProductOrderStatus.processing,
        'COMPLETED' => ProductOrderStatus.completed,
        'CANCELLED' => ProductOrderStatus.cancelled,
        _ => ProductOrderStatus.pending,
      };
}

class ProductOrderItem {
  const ProductOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  factory ProductOrderItem.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null ||
        json['productId'] == null ||
        json['productName'] == null) {
      throw const FormatException('Incomplete order item payload');
    }
    return ProductOrderItem(
      id: '${json['id']}',
      productId: '${json['productId']}',
      productName: '${json['productName']}',
      unitPrice: _double(json['unitPrice']),
      quantity: _int(json['quantity']),
      lineTotal: _double(json['lineTotal']),
    );
  }
}

class ProductOrderModel {
  const ProductOrderModel({
    required this.id,
    required this.customerId,
    required this.supplierId,
    required this.totalAmount,
    required this.status,
    required this.items,
    this.createdAt,
    this.customerName,
    this.supplierName,
  });

  final String id;
  final String customerId;
  final String supplierId;
  final double totalAmount;
  final ProductOrderStatus status;
  final List<ProductOrderItem> items;
  final DateTime? createdAt;
  final String? customerName;
  final String? supplierName;

  factory ProductOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (json['id'] == null ||
        json['customerId'] == null ||
        json['supplierId'] == null ||
        rawItems is! List) {
      throw const FormatException('Incomplete product order payload');
    }
    return ProductOrderModel(
      id: '${json['id']}',
      customerId: '${json['customerId']}',
      supplierId: '${json['supplierId']}',
      totalAmount: _double(json['totalAmount']),
      status: ProductOrderStatusX.fromString(json['status']?.toString()),
      items: rawItems
          .map(
            (item) => ProductOrderItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      customerName: json['customerName']?.toString(),
      supplierName: json['supplierName']?.toString(),
    );
  }
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
