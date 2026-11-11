import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/auth/screens/session_home_screen.dart';
import 'package:service_hub/features/inventory/services/inventory_product_service.dart';

void main() {
  const product = <String, dynamic>{
    'id': 'product-1',
    'supplierId': 'supplier-1',
    'supplierName': 'Local Supplier',
    'name': 'Olive Oil',
    'category': 'Food',
    'price': 250.0,
    'available': true,
    'quantityAvailable': 8,
  };

  InventoryProductService serviceFor(MockClientHandler handler) {
    return InventoryProductService(
      api: ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient(handler),
        readToken: () async => 'customer-token',
      ),
    );
  }

  test(
    'available inventory is public and parsed from the product catalog',
    () async {
      late http.Request sent;
      final service = serviceFor((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'content': [product],
          }),
          200,
        );
      });

      final result = await service.fetchAvailable(search: 'Olive Oil');

      expect(sent.url.path, '/api/products');
      expect(sent.url.queryParameters['search'], 'Olive Oil');
      expect(sent.headers.containsKey('authorization'), isFalse);
      expect(result.single.name, 'Olive Oil');
      expect(result.single.quantityAvailable, 8);
    },
  );

  test('supplier inventory uses authenticated supplier endpoint', () async {
    late http.Request sent;
    final service = serviceFor((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          'content': [product],
        }),
        200,
      );
    });

    final result = await service.fetchMyProducts();

    expect(sent.url.path, '/api/products/my');
    expect(sent.headers['authorization'], 'Bearer customer-token');
    expect(result.single.id, 'product-1');
  });

  test('inventory details use the public product endpoint', () async {
    late http.Request sent;
    final service = serviceFor((request) async {
      sent = request;
      return http.Response(jsonEncode(product), 200);
    });

    final result = await service.fetchProduct('product-1');

    expect(sent.url.path, '/api/products/product-1');
    expect(sent.headers.containsKey('authorization'), isFalse);
    expect(result.name, 'Olive Oil');
    expect(result.supplierName, 'Local Supplier');
  });

  testWidgets('catalog opens the inventory details screen', (tester) async {
    final service = serviceFor(
      (request) async => http.Response(
        jsonEncode({
          'content': [product],
        }),
        200,
      ),
    );
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
        api: service.api,
        child: const MaterialApp(home: SessionHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse Inventory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory Details'), findsOneWidget);
    expect(find.text('Olive Oil'), findsOneWidget);
    expect(find.text('Sold by Local Supplier'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);
  });

  test('buying inventory creates an order for the selected quantity', () async {
    late http.Request sent;
    final service = serviceFor((request) async {
      sent = request;
      return http.Response('{}', 200);
    });

    await service.buyProduct('product-1', 3);

    expect(sent.url.path, '/api/orders');
    expect(sent.headers['authorization'], 'Bearer customer-token');
    expect(jsonDecode(sent.body), {
      'items': [
        {'productId': 'product-1', 'quantity': 3},
      ],
    });
  });
}
