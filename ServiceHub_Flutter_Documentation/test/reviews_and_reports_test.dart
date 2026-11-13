import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/app/app_routes.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/bookings/models/booking_model.dart';
import 'package:service_hub/features/bookings/screens/booking_details_screen.dart';
import 'package:service_hub/features/reports/models/report_target.dart';
import 'package:service_hub/features/reports/screens/report_form_screen.dart';
import 'package:service_hub/features/reports/services/report_service.dart';
import 'package:service_hub/features/reviews/screens/review_form_screen.dart';
import 'package:service_hub/features/reviews/services/review_service.dart';

void main() {
  const reviewResponse = <String, dynamic>{
    'id': 'review-1',
    'bookingId': 'booking-1',
    'customerId': 'customer-1',
    'providerId': 'provider-1',
    'serviceId': 'service-1',
    'rating': 5,
    'comment': 'Great work.',
    'createdAt': '2026-02-01T10:00:00Z',
  };
  final booking = BookingModel(
    id: 'booking-1',
    customerId: 'customer-1',
    providerId: 'provider-1',
    serviceId: 'service-1',
    serviceTitle: 'Home repair',
    price: 80,
    description: 'Fix a leaking tap',
    preferredDateTime: DateTime(2026, 2, 1, 10),
    status: BookingStatus.completed,
  );

  ApiClient apiFor(MockClientHandler handler) => ApiClient(
    baseUrl: 'http://localhost:8080',
    client: MockClient(handler),
    readToken: () async => 'test-token',
  );

  test(
    'review service posts the expected booking and rating payload',
    () async {
      late http.Request sent;
      final service = ReviewService(
        api: apiFor((request) async {
          sent = request;
          return http.Response(jsonEncode(reviewResponse), 201);
        }),
      );

      final review = await service.submit(
        bookingId: 'booking-1',
        rating: 5,
        comment: '  Great work.  ',
      );

      expect(sent.url.path, '/api/reviews');
      expect(sent.method, 'POST');
      expect(jsonDecode(sent.body), {
        'bookingId': 'booking-1',
        'rating': 5,
        'comment': 'Great work.',
      });
      expect(review.bookingId, 'booking-1');
      expect(review.rating, 5);
    },
  );

  test('review service parses service reviews returned as a list', () async {
    late http.Request sent;
    final service = ReviewService(
      api: apiFor((request) async {
        sent = request;
        return http.Response(jsonEncode([reviewResponse]), 200);
      }),
    );

    final reviews = await service.forService('service-1');

    expect(sent.url.path, '/api/services/service-1/reviews');
    expect(reviews.single.comment, 'Great work.');
  });

  test(
    'report service submits target, reason and optional description',
    () async {
      late http.Request sent;
      final service = ReportService(
        api: apiFor((request) async {
          sent = request;
          return http.Response('{}', 201);
        }),
      );

      await service.submit(
        targetType: 'SERVICE',
        targetId: 'service-uuid',
        reason: 'Safety concern',
        description: '  Unsafe work area.  ',
      );

      expect(sent.url.path, '/api/reports');
      expect(sent.method, 'POST');
      expect(jsonDecode(sent.body), {
        'targetType': 'SERVICE',
        'targetId': 'service-uuid',
        'reason': 'Safety concern',
        'description': 'Unsafe work area.',
      });
    },
  );

  test(
    'report service parses only the signed-in user report list endpoint',
    () async {
      late http.Request sent;
      final service = ReportService(
        api: apiFor((request) async {
          sent = request;
          return http.Response(
            jsonEncode([
              {
                'id': 'report-1',
                'targetType': 'SERVICE',
                'targetId': 'service-1',
                'reason': 'Spam',
                'description': '',
                'status': 'PENDING',
                'createdAt': '2026-02-01T10:00:00Z',
              },
            ]),
            200,
          );
        }),
      );

      final reports = await service.myReports();

      expect(sent.url.path, '/api/reports/my');
      expect(reports.single.status, 'PENDING');
    },
  );

  testWidgets('review form requires a star rating before submission', (
    tester,
  ) async {
    late http.Request sent;
    final service = ReviewService(
      api: apiFor((request) async {
        sent = request;
        return http.Response(jsonEncode(reviewResponse), 201);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewFormScreen(booking: booking, reviewService: service),
      ),
    );
    await tester.pumpAndSettle();

    var submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit review'),
    );
    expect(submitButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('review-star-5')));
    await tester.pump();
    submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Submit review'),
    );
    expect(submitButton.onPressed, isNotNull);

    await tester.enterText(find.byType(TextField), 'Helpful and professional.');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit review'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit review'));
    await tester.pumpAndSettle();

    expect(sent.url.path, '/api/reviews');
    expect(jsonDecode(sent.body)['rating'], 5);
    expect(jsonDecode(sent.body)['comment'], 'Helpful and professional.');
    expect(find.text('Thank you for your review!'), findsOneWidget);
  });

  testWidgets(
    'report form requires a reason and shows submission confirmation',
    (tester) async {
      late http.Request sent;
      final service = ReportService(
        api: apiFor((request) async {
          sent = request;
          return http.Response('{}', 201);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReportFormScreen(
            target: const ReportTarget(
              type: 'SERVICE',
              id: 'service-1',
              title: 'Report service',
              subtitle: 'Home repair',
            ),
            reportService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Submit report'),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Safety concern').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'This service seems unsafe.',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Submit report'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
      await tester.pumpAndSettle();

      expect(sent.url.path, '/api/reports');
      expect(jsonDecode(sent.body)['reason'], 'Safety concern');
      expect(
        jsonDecode(sent.body)['description'],
        'This service seems unsafe.',
      );
      expect(find.text('Thank you for letting us know'), findsOneWidget);
    },
  );

  testWidgets('completed booking owner can review once; duplicate is hidden', (
    tester,
  ) async {
    final api = apiFor((request) async {
      if (request.url.path == '/api/bookings/booking-1') {
        return http.Response(jsonEncode(booking.toJson()), 200);
      }
      if (request.url.path == '/api/services/service-1/reviews') {
        return http.Response(jsonEncode([reviewResponse]), 200);
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'customer-1',
          fullName: 'Customer',
          email: 'customer@example.com',
          role: UserRole.customer,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: api,
        child: const MaterialApp(
          home: BookingDetailsScreen(bookingId: 'booking-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You reviewed this booking'), findsOneWidget);
    expect(find.text('Write a review'), findsNothing);
  });

  testWidgets('completed booking owner sees review action when not reviewed', (
    tester,
  ) async {
    final api = apiFor((request) async {
      if (request.url.path == '/api/bookings/booking-1') {
        return http.Response(jsonEncode(booking.toJson()), 200);
      }
      if (request.url.path == '/api/services/service-1/reviews') {
        return http.Response('[]', 200);
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'customer-1',
          fullName: 'Customer',
          email: 'customer@example.com',
          role: UserRole.customer,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: api,
        child: const MaterialApp(
          home: BookingDetailsScreen(bookingId: 'booking-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Write a review'), findsOneWidget);
  });

  testWidgets('native back after reviewing refreshes the completed booking', (
    tester,
  ) async {
    var hasReview = false;
    final api = apiFor((request) async {
      if (request.url.path == '/api/bookings/booking-1') {
        return http.Response(jsonEncode(booking.toJson()), 200);
      }
      if (request.url.path == '/api/services/service-1/reviews') {
        return http.Response(
          jsonEncode(hasReview ? [reviewResponse] : []),
          200,
        );
      }
      if (request.url.path == '/api/reviews' && request.method == 'POST') {
        hasReview = true;
        return http.Response(jsonEncode(reviewResponse), 201);
      }
      return http.Response('{}', 404);
    });
    final reviewService = ReviewService(api: api);

    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'customer-1',
          fullName: 'Customer',
          email: 'customer@example.com',
          role: UserRole.customer,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: api,
        child: MaterialApp(
          home: const BookingDetailsScreen(bookingId: 'booking-1'),
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.createReview) {
              return MaterialPageRoute<void>(
                builder: (_) => ReviewFormScreen(
                  booking: settings.arguments! as BookingModel,
                  reviewService: reviewService,
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write a review'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('review-star-4')));
    await tester.pump();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Submit review'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit review'));
    await tester.pumpAndSettle();
    expect(find.text('Thank you for your review!'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('You reviewed this booking'), findsOneWidget);
    expect(find.text('Write a review'), findsNothing);
  });
}
