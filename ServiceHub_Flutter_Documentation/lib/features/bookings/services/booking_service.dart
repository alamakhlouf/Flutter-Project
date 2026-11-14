import '../../../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/availability_model.dart';

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

  // Availability & Calendar Methods
  Future<List<ProviderAvailability>> fetchMyAvailability() async {
    final response = await api.getJson('/api/providers/me/availability', authenticated: true);
    if (response is List) {
      return response.map((e) => ProviderAvailability.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }

  Future<List<ProviderAvailability>> updateMyAvailability(List<ProviderAvailability> availability) async {
    final body = availability.map((a) => a.toJson()).toList();
    final response = await api.putJson(
      '/api/providers/me/availability',
      body: body,
      authenticated: true,
    );
    if (response is List) {
      return response.map((e) => ProviderAvailability.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }

  Future<ProviderUnavailableDate> addUnavailableDate({
    required DateTime date,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    final response = await api.post(
      '/api/providers/me/unavailable-dates',
      body: body,
      authenticated: true,
    );
    return ProviderUnavailableDate.fromJson(response is Map<String, dynamic> ? response : Map<String, dynamic>.from(response as Map));
  }

  Future<void> deleteUnavailableDate(String id) async {
    await api.delete(
      '/api/providers/me/unavailable-dates/$id',
      authenticated: true,
    );
  }

  Future<List<AvailableSlot>> fetchAvailableSlots({
    required String providerId,
    required DateTime date,
  }) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await api.getJson('/api/providers/$providerId/available-slots?date=$dateStr', authenticated: true);
    if (response is List) {
      return response.map((e) => AvailableSlot.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
  }

  Future<List<ProviderCalendarDay>> fetchProviderCalendar({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    final response = await api.getJson('/api/providers/me/calendar?startDate=$startStr&endDate=$endStr', authenticated: true);
    if (response is List) {
      return response.map((e) => ProviderCalendarDay.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map))).toList();
    }
    return [];
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
