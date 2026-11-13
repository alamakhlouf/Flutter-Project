import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/bookings/screens/booking_details_screen.dart';
import 'package:service_hub/features/bookings/screens/booking_list_screen.dart';

void main() {
  ApiClient createApiClient() {
    return ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient(
        (request) async => request.url.path == '/api/bookings/my'
            ? http.Response('{"content":[]}', 200)
            : http.Response('{"message":"Not found"}', 404),
      ),
      readToken: () async => 'test-token',
    );
  }

  Widget appWithAuthScope(Widget screen) {
    return AuthScope(
      user: const AuthUser(
        id: 'customer-1',
        fullName: 'Test Customer',
        email: 'customer@example.com',
        role: UserRole.customer,
      ),
      logout: () async {},
      updateUser: (_) {},
      api: createApiClient(),
      child: MaterialApp(home: screen),
    );
  }

  testWidgets('booking list reads AuthScope after initialization', (
    tester,
  ) async {
    await tester.pumpWidget(appWithAuthScope(const BookingListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('My service bookings'), findsOneWidget);
    expect(find.text('No bookings found.'), findsOneWidget);
  });

  testWidgets('booking details reads AuthScope after initialization', (
    tester,
  ) async {
    await tester.pumpWidget(
      appWithAuthScope(const BookingDetailsScreen(bookingId: 'booking-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Booking Details'), findsOneWidget);
    expect(find.text('Not found'), findsOneWidget);
  });
}
