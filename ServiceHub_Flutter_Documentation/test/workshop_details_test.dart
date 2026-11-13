import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/workshops/models/workshop_model.dart';
import 'package:service_hub/features/workshops/screens/workshop_details_screen.dart';
import 'package:service_hub/features/workshops/screens/workshop_form_screen.dart';
import 'package:service_hub/features/workshops/utils/workshop_date_format.dart';
import 'package:service_hub/features/workshops/widgets/workshop_image.dart';

void main() {
  const workshopId = 'workshop-1';
  final registration = <String, dynamic>{
    'id': 'registration-1',
    'workshopId': workshopId,
    'participantId': 'customer-1',
    'status': 'REGISTERED',
    'registeredAt': '2026-11-11T12:00:00Z',
  };
  final workshop = WorkshopModel(
    id: workshopId,
    organizerId: 'provider-1',
    organizerName: 'Test Provider',
    title: 'Flutter Workshop',
    description: 'Learn Flutter.',
    category: 'Technology',
    startDateTime: DateTime.now().add(const Duration(days: 3)),
    endDateTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
    location: 'Online',
    capacity: 10,
    registrationDeadline: DateTime.now().add(const Duration(days: 2)),
    status: WorkshopStatus.published,
    participantCount: 1,
    coverImageUrl: 'https://example.com/workshop.jpg',
  );

  test('workshop date formatting is readable and zero-padded', () {
    expect(
      formatWorkshopDateTime(DateTime(2023, 2, 13, 14, 5)),
      'monday 13 february 2023 at 14:05',
    );
  });

  testWidgets('workshop form submits its optional cover image URL', (
    tester,
  ) async {
    late http.Request sent;
    const imageUrl = 'https://example.com/workshop.jpg';
    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'provider-1',
          fullName: 'Test Provider',
          email: 'provider@example.com',
          role: UserRole.provider,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: ApiClient(
          baseUrl: 'http://localhost:8080',
          client: MockClient((request) async {
            sent = request;
            final response =
                Map<String, dynamic>.from(jsonDecode(request.body) as Map)
                  ..addAll({
                    'id': 'workshop-new',
                    'organizerId': 'provider-1',
                    'organizerName': 'Test Provider',
                    'status': 'DRAFT',
                    'participantCount': 0,
                  });
            return http.Response(jsonEncode(response), 200);
          }),
          readToken: () async => 'test-token',
        ),
        child: const MaterialApp(home: WorkshopFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Flutter Basics');
    await tester.enterText(find.byType(TextFormField).at(2), 'Technology');
    await tester.enterText(find.byType(TextFormField).at(3), 'Online');
    await tester.enterText(find.byType(TextFormField).at(5), imageUrl);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save workshop'));
    await tester.pumpAndSettle();

    expect(sent.url.path, '/api/workshops');
    expect(jsonDecode(sent.body)['coverImageUrl'], imageUrl);
  });

  Widget buildApp(MockClientHandler handler) {
    return AuthScope(
      user: const AuthUser(
        id: 'customer-1',
        fullName: 'Test Customer',
        email: 'customer@example.com',
        role: UserRole.customer,
      ),
      logout: () async {},
      updateUser: (_) {},
      api: ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient(handler),
        readToken: () async => 'test-token',
      ),
      child: MaterialApp(home: WorkshopDetailsScreen(workshop: workshop)),
    );
  }

  testWidgets(
    'shows Registered when the user already has an active registration',
    (tester) async {
      await tester.pumpWidget(
        buildApp((_) async => http.Response(jsonEncode([registration]), 200)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WorkshopImage), findsOneWidget);
      expect(
        find.text(formatWorkshopDateTime(workshop.startDateTime)),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.text('Registered'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Registered'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('changes to Registered after registering successfully', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp((request) async {
        if (request.url.path == '/api/workshops/my/registrations') {
          return http.Response('[]', 200);
        }
        if (request.url.path == '/api/workshops/$workshopId/registrations' &&
            request.method == 'POST') {
          return http.Response(jsonEncode(registration), 200);
        }
        return http.Response('{}', 404);
      }),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.text('Registered'), findsOneWidget);
  });
}
