import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/bookings/models/booking_model.dart';
import 'package:service_hub/features/bookings/services/booking_service.dart';

void main() {
  const bookingId = '11111111-2222-3333-4444-555555555555';
  const customerId = '22222222-3333-4444-5555-666666666666';
  const providerId = '99999999-8888-7777-6666-555555555555';
  const serviceId = '33333333-4444-5555-6666-777777777777';

  final sampleBookingJson = <String, dynamic>{
    'id': bookingId,
    'customerId': customerId,
    'providerId': providerId,
    'serviceId': serviceId,
    'serviceTitle': 'Deep Cleaning',
    'price': 120.0,
    'description': 'Please clean 3 rooms.',
    'preferredDateTime': '2026-12-01T10:00:00Z',
    'status': 'PENDING',
    'createdAt': '2026-11-09T12:00:00Z',
  };

  BookingService buildService(MockClientHandler handler) {
    return BookingService(
      api: ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient(handler),
        readToken: () async => 'test-jwt-token',
      ),
    );
  }

  test('fetchMyBookings sends authenticated GET /api/bookings/my', () async {
    late String path;
    late String? authHeader;
    final service = buildService((request) async {
      path = request.url.path;
      authHeader = request.headers['authorization'];
      return http.Response(
        jsonEncode({
          'content': [sampleBookingJson],
        }),
        200,
      );
    });

    final results = await service.fetchMyBookings();

    expect(path, '/api/bookings/my');
    expect(authHeader, 'Bearer test-jwt-token');
    expect(results.length, 1);
    expect(results.first.id, bookingId);
    expect(results.first.serviceTitle, 'Deep Cleaning');
    expect(results.first.status, BookingStatus.pending);
  });

  test('getBookingById sends GET /api/bookings/{id}', () async {
    late String path;
    final service = buildService((request) async {
      path = request.url.path;
      return http.Response(jsonEncode(sampleBookingJson), 200);
    });

    final result = await service.getBookingById(bookingId);

    expect(path, '/api/bookings/$bookingId');
    expect(result.id, bookingId);
    expect(result.price, 120.0);
  });

  test('createBooking sends POST /api/bookings with request body', () async {
    late String method;
    late String path;
    late Map<String, dynamic> body;
    final service = buildService((request) async {
      method = request.method;
      path = request.url.path;
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode(sampleBookingJson), 201);
    });

    final preferredTime = DateTime.parse('2026-12-01T10:00:00Z');
    final created = await service.createBooking(
      serviceId: serviceId,
      preferredDateTime: preferredTime,
      description: 'Please clean 3 rooms.',
    );

    expect(method, 'POST');
    expect(path, '/api/bookings');
    expect(body['serviceId'], serviceId);
    expect(body['description'], 'Please clean 3 rooms.');
    expect(created.id, bookingId);
  });

  test('updateBookingStatus sends PATCH /api/bookings/{id}/status', () async {
    late String method;
    late String path;
    late Map<String, dynamic> body;
    final service = buildService((request) async {
      method = request.method;
      path = request.url.path;
      body = jsonDecode(request.body) as Map<String, dynamic>;
      final updatedJson = Map<String, dynamic>.from(sampleBookingJson);
      updatedJson['status'] = 'ACCEPTED';
      return http.Response(jsonEncode(updatedJson), 200);
    });

    final updated = await service.updateBookingStatus(
      id: bookingId,
      status: BookingStatus.accepted,
    );

    expect(method, 'PATCH');
    expect(path, '/api/bookings/$bookingId/status');
    expect(body['status'], 'ACCEPTED');
    expect(updated.status, BookingStatus.accepted);
  });

  test('cancelBooking sends PATCH /api/bookings/{id}/cancel', () async {
    late String method;
    late String path;
    final service = buildService((request) async {
      method = request.method;
      path = request.url.path;
      final cancelledJson = Map<String, dynamic>.from(sampleBookingJson);
      cancelledJson['status'] = 'CANCELLED';
      return http.Response(jsonEncode(cancelledJson), 200);
    });

    final cancelled = await service.cancelBooking(bookingId);

    expect(method, 'PATCH');
    expect(path, '/api/bookings/$bookingId/cancel');
    expect(cancelled.status, BookingStatus.cancelled);
  });
}
