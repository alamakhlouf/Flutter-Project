typedef Product = InventoryProduct;

class InventoryProduct {
  const InventoryProduct({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.name,
    required this.category,
    required this.price,
    required this.available,
    this.description,
    this.imageUrl,
    this.quantityAvailable,
    this.favorite = false,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final String name;
  final String category;
  final double price;
  final bool available;
  final String? description;
  final String? imageUrl;
  final int? quantityAvailable;
  final bool favorite;

  InventoryProduct copyWith({
    bool? favorite,
    bool? available,
    int? quantityAvailable,
  }) {
    return InventoryProduct(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      name: name,
      category: category,
      price: price,
      available: available ?? this.available,
      description: description,
      imageUrl: imageUrl,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      favorite: favorite ?? this.favorite,
    );
  }

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final supplierId = json['supplierId'];
    final supplierName = json['supplierName'];
    final name = json['name'];
    final category = json['category'];
    final price = json['price'];
    if (id == null ||
        supplierId == null ||
        supplierName is! String ||
        name is! String ||
        category is! String ||
        price is! num) {
      throw const FormatException('Incomplete inventory product payload');
    }

    final quantity = json['quantityAvailable'];
    return InventoryProduct(
      id: id.toString(),
      supplierId: supplierId.toString(),
      supplierName: supplierName,
      name: name,
      category: category,
      price: price.toDouble(),
      available: json['available'] == true,
      description: _optionalString(json['description']),
      imageUrl: _optionalString(json['imageUrl']),
      quantityAvailable: quantity is num ? quantity.toInt() : null,
      favorite: json['favorite'] == true,
    );
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    throw const FormatException('Unexpected inventory product field');
  }
}
