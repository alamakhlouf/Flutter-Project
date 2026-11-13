import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/workshops/screens/workshop_management_screen.dart';

void main() {
  testWidgets('registration list shows workshop details and date', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.url.path, '/api/workshops/my/registrations');
        return http.Response(
          jsonEncode([
            {
              'id': 'registration-1',
              'workshopId': 'workshop-1',
              'workshopTitle': 'Home Repair Basics',
              'workshopLocation': 'Community Hall',
              'workshopStartDateTime': '2025-02-12T14:30:00',
              'workshopStatus': 'PUBLISHED',
              'organizerName': 'Alex Provider',
              'participantId': 'customer-1',
              'status': 'REGISTERED',
              'registeredAt': '2025-02-01T10:00:00',
            },
          ]),
          200,
        );
      }),
      readToken: () async => 'test-token',
    );

    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'customer-1',
          fullName: 'Test customer',
          email: 'customer@example.com',
          role: UserRole.customer,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: api,
        child: const MaterialApp(
          home: WorkshopManagementScreen(registrations: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home Repair Basics'), findsOneWidget);
    expect(find.textContaining('Hosted by Alex Provider'), findsOneWidget);
    expect(
      find.textContaining('wednesday 12 february 2025 at 14:30'),
      findsOneWidget,
    );
    expect(find.textContaining('Community Hall'), findsOneWidget);
    expect(find.textContaining('Registration registered'), findsOneWidget);
    expect(find.byTooltip('Cancel registration'), findsOneWidget);
  });
}
