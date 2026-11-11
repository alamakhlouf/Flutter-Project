import '../../../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingService {
  BookingService({required this.api});

  final ApiClient api;

  Future<List<BookingModel>> fetchMyBookings() async {
    final response = await api.getJson('/api/bookings/my', authenticated: true);
    return _parseList(response);
  }

  Future<BookingModel> getBookingById(String id) async {
    final response = await api.get('/api/bookings/$id', authenticated: true);
    return BookingModel.fromJson(response);
  }

  Future<BookingModel> createBooking({
    required String serviceId,
    required DateTime preferredDateTime,
    required String description,
  }) async {
    final body = <String, dynamic>{
      'serviceId': serviceId,
      'preferredDateTime': preferredDateTime.toIso8601String(),
      'description': description.trim(),
    };

    final response = await api.post(
      '/api/bookings',
      body: body,
      authenticated: true,
    );
    return BookingModel.fromJson(response);
  }

  Future<BookingModel> updateBookingStatus({
    required String id,
    required BookingStatus status,
  }) async {
    final response = await api.patch(
      '/api/bookings/$id/status',
      body: {'status': status.label},
      authenticated: true,
    );
    return BookingModel.fromJson(response);
  }

  Future<BookingModel> cancelBooking(String id) async {
    final response = await api.patch(
      '/api/bookings/$id/cancel',
      authenticated: true,
    );
    return BookingModel.fromJson(response);
  }

  List<BookingModel> _parseList(Object? response) {
    if (response is List) {
      return response.map(_parseBooking).toList();
    }
    if (response is! Map) {
      throw const FormatException('Unexpected bookings response');
    }

    final rawList =
        response['content'] ??
        response['bookings'] ??
        response['items'] ??
        response['data'];

    if (rawList is List) {
      return rawList.map(_parseBooking).toList();
    }

    if (response.containsKey('id')) {
      return [_parseBooking(response)];
    }

    throw const FormatException('Unexpected bookings response');
  }

  BookingModel _parseBooking(Object? item) {
    if (item is Map<String, dynamic>) return BookingModel.fromJson(item);
    if (item is Map) {
      return BookingModel.fromJson(Map<String, dynamic>.from(item));
    }
    throw const FormatException('Unexpected booking item');
  }
}
