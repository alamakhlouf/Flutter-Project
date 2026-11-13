import '../../../core/network/api_client.dart';
import '../models/review_model.dart';

class ReviewService {
  ReviewService({required this.api});

  final ApiClient api;

  Future<ReviewModel> submit({
    required String bookingId,
    required int rating,
    required String comment,
  }) async {
    final response = await api.post(
      '/api/reviews',
      authenticated: true,
      body: {
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment.trim(),
      },
    );
    return ReviewModel.fromJson(response);
  }

  Future<List<ReviewModel>> forService(String serviceId) async {
    return _parseList(await api.getJson('/api/services/$serviceId/reviews'));
  }

  Future<List<ReviewModel>> forProvider(String providerId) async {
    return _parseList(await api.getJson('/api/providers/$providerId/reviews'));
  }

  List<ReviewModel> _parseList(Object? response) {
    final raw = response is List
        ? response
        : response is Map
        ? response['content'] ?? response['items']
        : null;
    if (raw is! List) {
      throw const FormatException('Unexpected reviews response');
    }
    return raw
        .map(
          (item) =>
              ReviewModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
