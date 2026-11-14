class ServiceCategory {
  const ServiceCategory._();

  static const homeCare = 'Home Care';
  static const cleaning = 'Cleaning';
  static const plumbing = 'Plumbing';
  static const electrical = 'Electrical';
  static const tutoring = 'Tutoring';
  static const beauty = 'Beauty & Wellness';
  static const fitness = 'Fitness & Sports';
  static const event = 'Event Services';
  static const other = 'Other';

  static const all = <String>[
    homeCare,
    cleaning,
    plumbing,
    electrical,
    tutoring,
    beauty,
    fitness,
    event,
    other,
  ];
}

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.category,
    this.price,
    this.priceDescription,
    this.location,
    this.imageUrl,
    this.isActive = true,
    this.favorite = false,
    this.providerName,
    this.providerEmail,
    this.providerPhone,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String providerId;
  final String title;
  final String description;
  final String category;
  final double? price;
  final String? priceDescription;
  final String? location;
  final String? imageUrl;
  final bool isActive;
  final bool favorite;
  final String? providerName;
  final String? providerEmail;
  final String? providerPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final providerId = json['providerId'];
    final title = json['title'];
    final description = json['description'];
    final category = json['category'];

    if (id == null ||
        id.toString().isEmpty ||
        providerId == null ||
        providerId.toString().isEmpty ||
        title is! String ||
        description is! String ||
        category is! String) {
      throw const FormatException('Incomplete service payload');
    }

    final priceRaw = json['price'];
    double? price;
    if (priceRaw is num) {
      price = priceRaw.toDouble();
    } else if (priceRaw is String && priceRaw.isNotEmpty) {
      price = double.tryParse(priceRaw);
    }

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

    return ServiceModel(
      id: id.toString(),
      providerId: providerId.toString(),
      title: title,
      description: description,
      category: category,
      price: price,
      priceDescription: _optionalString(json['priceDescription']),
      location: _optionalString(json['location']),
      imageUrl: _optionalString(json['imageUrl']),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      favorite: json['favorite'] == true,
      providerName: _optionalString(json['providerName']),
      providerEmail: _optionalString(json['providerEmail']),
      providerPhone: _optionalString(json['providerPhone']),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'title': title,
      'description': description,
      'category': category,
      if (price != null) 'price': price,
      if (priceDescription != null) 'priceDescription': priceDescription,
      if (location != null) 'location': location,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isActive': isActive,
      'favorite': favorite,
      if (providerName != null) 'providerName': providerName,
      if (providerEmail != null) 'providerEmail': providerEmail,
      if (providerPhone != null) 'providerPhone': providerPhone,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    String? category,
    double? price,
    String? priceDescription,
    String? location,
    String? imageUrl,
    bool? isActive,
    bool? favorite,
    String? providerName,
    String? providerEmail,
    String? providerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      priceDescription: priceDescription ?? this.priceDescription,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      favorite: favorite ?? this.favorite,
      providerName: providerName ?? this.providerName,
      providerEmail: providerEmail ?? this.providerEmail,
      providerPhone: providerPhone ?? this.providerPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  String get formattedPrice {
    if (price != null && price! > 0) {
      return '\$${price!.toStringAsFixed(2)}';
    }
    if (priceDescription != null && priceDescription!.trim().isNotEmpty) {
      return priceDescription!.trim();
    }
    return 'Contact for pricing';
  }

  @override
  bool operator ==(Object other) {
    return other is ServiceModel &&
        other.id == id &&
        other.providerId == providerId &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.price == price &&
        other.priceDescription == priceDescription &&
        other.location == location &&
        other.imageUrl == imageUrl &&
        other.isActive == isActive &&
        other.favorite == favorite &&
        other.providerName == providerName &&
        other.providerEmail == providerEmail &&
        other.providerPhone == providerPhone;
  }

  @override
  int get hashCode => Object.hash(
        id,
        providerId,
        title,
        description,
        category,
        price,
        priceDescription,
        location,
        imageUrl,
        isActive,
        favorite,
        providerName,
        providerEmail,
        providerPhone,
      );
}
