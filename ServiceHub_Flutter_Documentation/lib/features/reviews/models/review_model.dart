class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.serviceId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final String serviceId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final bookingId = json['bookingId'];
    final customerId = json['customerId'];
    final providerId = json['providerId'];
    final serviceId = json['serviceId'];
    final rating = json['rating'];
    if (id == null ||
        bookingId == null ||
        customerId == null ||
        providerId == null ||
        serviceId == null ||
        rating is! num ||
        rating < 1 ||
        rating > 5) {
      throw const FormatException('Incomplete review payload');
    }

    return ReviewModel(
      id: id.toString(),
      bookingId: bookingId.toString(),
      customerId: customerId.toString(),
      providerId: providerId.toString(),
      serviceId: serviceId.toString(),
      rating: rating.toInt(),
      comment: json['comment']?.toString() ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
