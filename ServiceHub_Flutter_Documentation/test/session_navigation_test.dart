import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/app/app_routes.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/design_system/app_colors.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/auth/screens/session_home_screen.dart';

void main() {
  testWidgets('notification links open notifications and related details', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/services':
          case '/api/products':
          case '/api/workshops':
            return http.Response(jsonEncode({'content': []}), 200);
          case '/api/notifications':
            return http.Response(
              jsonEncode([
                {
                  'id': 'notification-order',
                  'title': 'Order updated',
                  'message': 'Your order is ready.',
                  'type': 'ORDER',
                  'relatedEntityType': 'Order',
                  'relatedEntityId': 'order-1',
                  'read': false,
                  'createdAt': DateTime.now().toIso8601String(),
                },
                {
                  'id': 'notification-workshop',
                  'title': 'Workshop update',
                  'message': 'A workshop changed.',
                  'type': 'WORKSHOP',
                  'relatedEntityType': 'Workshop',
                  'relatedEntityId': 'workshop-1',
                  'read': false,
                  'createdAt': DateTime.now().toIso8601String(),
                },
              ]),
              200,
            );
          case '/api/orders/order-1':
            return http.Response(
              jsonEncode({
                'id': 'order-1',
                'customerId': 'customer-1',
                'supplierId': 'supplier-1',
                'totalAmount': 12.5,
                'status': 'COMPLETED',
                'items': [
                  {
                    'id': 'item-1',
                    'productId': 'product-1',
                    'productName': 'Soap',
                    'unitPrice': 12.5,
                    'quantity': 1,
                    'lineTotal': 12.5,
                  },
                ],
              }),
              200,
            );
          case '/api/workshops/workshop-1':
            return http.Response(
              jsonEncode({
                'id': 'workshop-1',
                'organizerId': 'provider-1',
                'organizerName': 'Provider',
                'title': 'First Aid Workshop',
                'description': 'Workshop details',
                'category': 'Health',
                'startDateTime': '2026-12-01T10:00:00',
                'endDateTime': '2026-12-01T12:00:00',
                'location': 'Community Hall',
                'capacity': 20,
                'registrationDeadline': '2026-11-30T10:00:00',
                'status': 'PUBLISHED',
                'participantCount': 0,
              }),
              200,
            );
          case '/api/workshops/my/registrations':
            return http.Response('[]', 200);
          case '/api/notifications/notification-order/read':
          case '/api/notifications/notification-workshop/read':
            return http.Response('{}', 200);
          default:
            return http.Response('{"message":"Not found"}', 404);
        }
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
    Navigator.of(tester.element(find.byKey(const ValueKey(AppRoutes.home))))
        .pushNamed(AppRoutes.notifications);
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    await tester.tap(find.text('Order updated'));
    await tester.pumpAndSettle();
    expect(find.text('Order details'), findsOneWidget);
    expect(find.text('Soap × 1'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workshop update'));
    await tester.pumpAndSettle();
    expect(find.text('First Aid Workshop'), findsOneWidget);
  });

  testWidgets('bottom navigation switches among the four main sections', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/services':
          case '/api/products':
          case '/api/workshops':
            return http.Response(jsonEncode({'content': []}), 200);
          case '/api/users/me':
            return http.Response(
              jsonEncode({
                'id': 'customer-1',
                'fullName': 'Test Customer',
                'email': 'customer@example.com',
                'role': 'CUSTOMER',
              }),
              200,
            );
          default:
            return http.Response('{"message":"Not found"}', 404);
        }
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

    expect(find.text('Services Catalog'), findsOneWidget);
    final bottomNavigation = tester.widget<Container>(
      find.byKey(const ValueKey('bottom_navigation_bar')),
    );
    expect(
      (bottomNavigation.decoration! as BoxDecoration).color,
      AppColors.navigationSurface,
    );
    final selectedServices = tester.widget<Container>(
      find.byKey(const ValueKey('bottom_nav_services')),
    );
    expect(
      (selectedServices.decoration! as BoxDecoration).color,
      AppColors.primary.withValues(alpha: 0.1),
    );
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Workshops'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom_nav_supplier')));
    await tester.pumpAndSettle();
    final selectedSupplier = tester.widget<Container>(
      find.byKey(const ValueKey('bottom_nav_supplier')),
    );
    expect(
      (selectedSupplier.decoration! as BoxDecoration).color,
      AppColors.primary.withValues(alpha: 0.1),
    );
    expect(find.text('Available Inventory'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bottom_nav_workshops')));
    await tester.pumpAndSettle();
    expect(find.text('Workshops'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bottom_nav_profile')));
    await tester.pumpAndSettle();
    expect(find.text('Personal details'), findsOneWidget);
    await tester.drag(
      find.descendant(
        of: find.byKey(const ValueKey(AppRoutes.profile)),
        matching: find.byType(ListView),
      ),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My activity'));
    await tester.pumpAndSettle();
    expect(find.text('My activity'), findsOneWidget);
    expect(find.text('Service bookings'), findsOneWidget);
    expect(find.text('Product orders'), findsOneWidget);
    expect(find.text('Workshop registrations'), findsOneWidget);
    expect(find.text('Incoming product orders'), findsNothing);
  });

  testWidgets('providers can find service, inventory, and workshop tools', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/services':
          case '/api/services/my':
          case '/api/products':
          case '/api/inventory':
          case '/api/workshops':
          case '/api/workshops/my/organized':
            return http.Response(jsonEncode({'content': []}), 200);
          default:
            return http.Response('{"message":"Not found"}', 404);
        }
      }),
      readToken: () async => 'test-token',
    );

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
        api: api,
        child: const MaterialApp(home: SessionHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create service'), findsOneWidget);
    await tester.tap(find.text('Create service'));
    await tester.pumpAndSettle();
    expect(find.text('Create Service'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('My Services'));
    await tester.pumpAndSettle();
    expect(find.text('My Services'), findsOneWidget);
    expect(find.text('Create Your First Service'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom_nav_supplier')));
    await tester.pumpAndSettle();
    expect(find.text('My inventory'), findsOneWidget);
    await tester.tap(find.text('My inventory'));
    await tester.pumpAndSettle();
    expect(find.text('My Inventory'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom_nav_workshops')));
    await tester.pumpAndSettle();
    expect(find.text('Create workshop'), findsOneWidget);
    await tester.tap(find.text('Create workshop'));
    await tester.pumpAndSettle();
    expect(find.text('Create workshop'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('My workshops'));
    await tester.pumpAndSettle();
    expect(find.text('My organized workshops'), findsOneWidget);
    expect(find.text('Create workshop'), findsOneWidget);
    await tester.tap(find.text('Create workshop'));
    await tester.pumpAndSettle();
    expect(find.text('Create workshop'), findsOneWidget);
  });

  testWidgets('suppliers can reach their product inventory management', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        switch (request.url.path) {
          case '/api/services':
          case '/api/workshops':
          case '/api/products':
          case '/api/products/my':
            return http.Response(jsonEncode({'content': []}), 200);
          default:
            return http.Response('{"message":"Not found"}', 404);
        }
      }),
      readToken: () async => 'test-token',
    );

    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'supplier-1',
          fullName: 'Test Supplier',
          email: 'supplier@example.com',
          role: UserRole.supplier,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: api,
        child: const MaterialApp(home: SessionHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('bottom_nav_supplier')));
    await tester.pumpAndSettle();
    expect(find.text('My inventory'), findsOneWidget);
    await tester.tap(find.text('My inventory'));
    await tester.pumpAndSettle();

    expect(find.text('My Inventory'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Available Inventory'), findsOneWidget);
  });
}
