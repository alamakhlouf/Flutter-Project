import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/app/app.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/auth/auth_keys.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/auth/screens/session_home_screen.dart';
import 'package:service_hub/features/auth/services/auth_service.dart';
import 'package:service_hub/features/services/services_keys.dart';

import 'support/memory_token_storage.dart';

void main() {
  const customerId = '11111111-1111-1111-1111-111111111111';
  const providerId = '22222222-2222-2222-2222-222222222222';
  const serviceId1 = '33333333-3333-3333-3333-333333333333';
  const serviceId2 = '44444444-4444-4444-4444-444444444444';

  Map<String, Object?> userPayload({
    required String id,
    required String name,
    required String email,
    required String role,
  }) {
    return {
      'id': id,
      'fullName': name,
      'email': email,
      'role': role,
      'phone': '+213555000111',
      'profileImageUrl': null,
    };
  }

  Map<String, Object?> serviceJson({
    required String id,
    required String providerId,
    required String title,
    required String category,
    required double price,
    required bool isActive,
  }) {
    return {
      'id': id,
      'providerId': providerId,
      'title': title,
      'description': 'Description for $title service in detail.',
      'category': category,
      'price': price,
      'priceDescription': 'per job',
      'location': 'Algiers',
      'imageUrl': null,
      'isActive': isActive,
      'providerName': 'Provider $providerId',
      'providerEmail': 'provider@example.com',
      'providerPhone': '+213555090909',
    };
  }

  Future<void> signIn(
    WidgetTester tester, {
    required http.Client client,
    required String email,
  }) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ServiceHubApp(
        authService: AuthService(
          tokenStorage: MemoryTokenStorage(),
          httpClient: client,
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(AuthKeys.loginEmail), email);
    await tester.enterText(find.byKey(AuthKeys.loginPassword), 'password123');
    await tester.tap(find.byKey(AuthKeys.loginSubmit));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('services catalog header opens favorite services', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        if (request.url.path == '/api/services') {
          return http.Response('{"content":[]}', 200);
        }
        if (request.url.path == '/api/services/favorites') {
          return http.Response('[]', 200);
        }
        return http.Response('{"message":"Not found"}', 404);
      }),
      readToken: () async => 'test-token',
    );

    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'customer-1',
          fullName: 'Test Customer',
          email: 'customer@example.com',
          role: UserRole.customer,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: api,
        child: const MaterialApp(home: SessionHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Filter services'), findsNothing);
    await tester.tap(find.byKey(ServicesKeys.catalogFavoritesButton));
    await tester.pumpAndSettle();
    expect(find.text('Favorite Services'), findsOneWidget);
    expect(find.text('No favorite services yet'), findsOneWidget);
  });

  testWidgets('Customer can browse catalog, filter, and view details', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/login') {
        return http.Response(
          jsonEncode({
            'token': 'customer-token',
            'user': userPayload(
              id: customerId,
              name: 'Carl Customer',
              email: 'customer@example.com',
              role: 'CUSTOMER',
            ),
          }),
          200,
        );
      }
      if (request.method == 'GET' && request.url.path == '/api/services') {
        return http.Response(
          jsonEncode({
            'content': [
              serviceJson(
                id: serviceId1,
                providerId: providerId,
                title: 'Plumbing Repair',
                category: 'Plumbing',
                price: 80.0,
                isActive: true,
              ),
              serviceJson(
                id: serviceId2,
                providerId: providerId,
                title: 'House Cleaning',
                category: 'Cleaning',
                price: 50.0,
                isActive: true,
              ),
            ],
          }),
          200,
        );
      }
      if (request.method == 'GET' &&
          request.url.path == '/api/services/$serviceId1') {
        return http.Response(
          jsonEncode(
            serviceJson(
              id: serviceId1,
              providerId: providerId,
              title: 'Plumbing Repair',
              category: 'Plumbing',
              price: 80.0,
              isActive: true,
            ),
          ),
          200,
        );
      }
      return http.Response('{"message":"Not found"}', 404);
    });

    await signIn(tester, client: client, email: 'customer@example.com');

    expect(find.byKey(const ValueKey('bottom_nav_services')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bottom_nav_services')));
    await tester.pumpAndSettle();

    expect(find.text('Services Catalog'), findsOneWidget);
    expect(find.text('Plumbing Repair'), findsOneWidget);
    expect(find.text('House Cleaning'), findsOneWidget);

    // Filter by Category Chip
    final plumbingChip = find.byKey(ServicesKeys.categoryChip('Plumbing'));
    expect(plumbingChip, findsOneWidget);
    await tester.tap(plumbingChip);
    await tester.pumpAndSettle();

    // Tap on Plumbing Repair card
    await tester.tap(find.text('Plumbing Repair'));
    await tester.pumpAndSettle();

    expect(find.text('Provider Information'), findsOneWidget);
    expect(find.text('\$80.00'), findsWidgets);
    expect(find.byKey(ServicesKeys.detailsBookButton), findsOneWidget);

    await tester.tap(find.byKey(ServicesKeys.detailsBookButton));
    await tester.pumpAndSettle();
    expect(find.text('Book Service'), findsOneWidget);
  });

  testWidgets('Provider can list, create, edit, toggle, and delete services', (
    tester,
  ) async {
    final services = <Map<String, Object?>>[
      serviceJson(
        id: serviceId1,
        providerId: providerId,
        title: 'Initial Service',
        category: 'Electrical',
        price: 100.0,
        isActive: true,
      ),
    ];

    Map<String, dynamic>? lastCreated;

    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/login') {
        return http.Response(
          jsonEncode({
            'token': 'provider-token',
            'user': userPayload(
              id: providerId,
              name: 'Pat Provider',
              email: 'provider@example.com',
              role: 'PROVIDER',
            ),
          }),
          200,
        );
      }
      if (request.method == 'GET' && request.url.path == '/api/services/my') {
        return http.Response(jsonEncode({'content': services}), 200);
      }
      if (request.method == 'POST' && request.url.path == '/api/services') {
        lastCreated = jsonDecode(request.body) as Map<String, dynamic>;
        final newService = serviceJson(
          id: serviceId2,
          providerId: providerId,
          title: lastCreated!['title'] as String,
          category: lastCreated!['category'] as String,
          price: (lastCreated!['price'] as num?)?.toDouble() ?? 0.0,
          isActive: true,
        );
        services.add(newService);
        return http.Response(jsonEncode(newService), 201);
      }
      if (request.method == 'PATCH' &&
          request.url.path == '/api/services/$serviceId1/status') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final current = services.firstWhere((s) => s['id'] == serviceId1);
        current['isActive'] = body['isActive'];
        return http.Response(jsonEncode(current), 200);
      }
      if (request.method == 'DELETE' &&
          request.url.path == '/api/services/$serviceId1') {
        services.removeWhere((s) => s['id'] == serviceId1);
        return http.Response('', 204);
      }
      return http.Response('{"message":"Not found"}', 404);
    });

    await signIn(tester, client: client, email: 'provider@example.com');

    expect(find.byKey(ServicesKeys.openMyServices), findsOneWidget);
    await tester.tap(find.byKey(ServicesKeys.openMyServices));
    await tester.pumpAndSettle();

    expect(find.text('My Services'), findsOneWidget);
    expect(find.text('Initial Service'), findsOneWidget);

    // Toggle active switch
    final toggle = find.byKey(ServicesKeys.toggleActiveSwitch(serviceId1));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    // Create service form validation & submission
    await tester.tap(find.byKey(ServicesKeys.createServiceButton).first);
    await tester.pumpAndSettle();

    expect(find.byKey(ServicesKeys.formSaveButton), findsOneWidget);

    // Test form validation
    await tester.tap(find.byKey(ServicesKeys.formSaveButton));
    await tester.pump();
    expect(find.text('Enter a service title.'), findsOneWidget);
    expect(find.text('Enter a service description.'), findsOneWidget);

    // Fill valid service details
    await tester.enterText(find.byKey(ServicesKeys.formTitle), 'New Lawn Care');
    await tester.enterText(
      find.byKey(ServicesKeys.formDescription),
      'Complete lawn mowing, trimming, and garden landscaping.',
    );
    await tester.enterText(find.byKey(ServicesKeys.formPrice), '60');
    await tester.tap(find.byKey(ServicesKeys.formSaveButton));
    await tester.pumpAndSettle();

    expect(find.text('Service created successfully!'), findsOneWidget);
    expect(lastCreated?['title'], 'New Lawn Care');
    expect(find.text('New Lawn Care'), findsOneWidget);

    // Delete service confirmation
    final deleteAction = find.byKey(
      ServicesKeys.deleteServiceAction(serviceId1),
    );
    expect(deleteAction, findsOneWidget);
    await tester.tap(deleteAction);
    await tester.pumpAndSettle();

    expect(find.text('Delete Service'), findsOneWidget);
    await tester.tap(find.byKey(ServicesKeys.confirmDeleteButton));
    await tester.pumpAndSettle();

    expect(find.text('Initial Service'), findsNothing);
  });
}
