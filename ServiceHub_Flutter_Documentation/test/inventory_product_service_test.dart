import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/auth/screens/session_home_screen.dart';
import 'package:service_hub/features/inventory/models/inventory_product_model.dart';
import 'package:service_hub/features/inventory/screens/inventory_details_screen.dart';
import 'package:service_hub/features/inventory/screens/supplier_inventory_form_screen.dart';
import 'package:service_hub/features/inventory/screens/supplier_inventory_screen.dart';
import 'package:service_hub/features/inventory/services/inventory_product_service.dart';
import 'package:service_hub/features/inventory/widgets/inventory_product_card.dart';

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

  test('saving a product sends and parses its image URL', () async {
    late http.Request sent;
    const imageUrl = 'https://example.com/products/valve.jpg';
    final service = serviceFor((request) async {
      sent = request;
      return http.Response(jsonEncode({...product, 'imageUrl': imageUrl}), 200);
    });

    final saved = await service.saveProduct(
      name: 'Brass ball valve',
      category: 'Plumbing',
      price: 12.5,
      description: '',
      quantityAvailable: 40,
      available: true,
      imageUrl: imageUrl,
    );

    expect(sent.url.path, '/api/products');
    expect(jsonDecode(sent.body)['imageUrl'], imageUrl);
    expect(saved.imageUrl, imageUrl);
  });

  testWidgets(
    'supplier inventory shows stock status and quantity to its owner',
    (tester) async {
      final service = serviceFor(
        (request) async => http.Response(
          jsonEncode({
            'content': [
              {...product, 'quantityAvailable': 40},
            ],
          }),
          200,
        ),
      );
      await tester.pumpWidget(
        AuthScope(
          user: const AuthUser(
            id: 'supplier-1',
            fullName: 'Local Supplier',
            email: 'supplier@example.com',
            role: UserRole.supplier,
          ),
          logout: () async {},
          updateUser: (_) {},
          api: service.api,
          child: MaterialApp(
            home: SupplierInventoryScreen(productService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('In stock'), findsOneWidget);
      expect(find.text('40 available'), findsOneWidget);
      expect(find.text('FOOD'), findsOneWidget);
    },
  );

  testWidgets('owner stock status warns below five available items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventoryProductCard(
            product: InventoryProduct.fromJson({
              ...product,
              'quantityAvailable': 4,
            }),
            showOwnerStockStatus: true,
            actions: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('4 available'), findsOneWidget);
  });

  testWidgets('supplier product form saves the entered image URL', (
    tester,
  ) async {
    late http.Request sent;
    const imageUrl = 'https://example.com/products/valve.jpg';
    final service = serviceFor((request) async {
      sent = request;
      return http.Response(
        jsonEncode({
          ...product,
          'name': 'Brass ball valve',
          'category': 'Plumbing',
          'imageUrl': imageUrl,
        }),
        200,
      );
    });

    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'supplier-1',
          fullName: 'Local Supplier',
          email: 'supplier@example.com',
          role: UserRole.supplier,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: service.api,
        child: MaterialApp(
          home: SupplierInventoryFormScreen(productService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Brass ball valve',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Plumbing');
    await tester.enterText(find.byType(TextFormField).at(2), '12.50');
    await tester.enterText(find.byType(TextFormField).at(4), imageUrl);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(sent.url.path, '/api/products');
    expect(jsonDecode(sent.body)['imageUrl'], imageUrl);
  });

  testWidgets('catalog product card fits a narrow phone viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: InventoryProductCard(
                product: InventoryProduct.fromJson(product),
                actions: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('View details'),
                    ),
                    FilledButton(onPressed: () {}, child: const Text('Buy')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('View details'), findsOneWidget);
    expect(find.text('\$250.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Supplier'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory Details'), findsOneWidget);
    expect(find.text('Olive Oil'), findsOneWidget);
    expect(find.text('Sold by Local Supplier'), findsOneWidget);
    expect(find.text('\$250.00'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Inventory Details'), findsNothing);
    expect(find.text('Available Inventory'), findsOneWidget);
  });

  testWidgets('placing an order from inventory details closes cleanly', (
    tester,
  ) async {
    final service = serviceFor((request) async {
      if (request.url.path == '/api/orders') {
        return http.Response('{}', 200);
      }
      return http.Response(
        jsonEncode({
          'content': [product],
        }),
        200,
      );
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
        api: service.api,
        child: const MaterialApp(home: SessionHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supplier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Inventory Details'), findsNothing);
    expect(find.text('Available Inventory'), findsOneWidget);
    expect(find.text('Order placed successfully.'), findsOneWidget);
  });

  testWidgets('placing an order from the catalog closes cleanly', (
    tester,
  ) async {
    final service = serviceFor((request) async {
      return http.Response(
        jsonEncode({
          'content': [product],
        }),
        200,
      );
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
        api: service.api,
        child: const MaterialApp(home: SessionHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supplier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Order placed successfully.'), findsOneWidget);
  });

  testWidgets('all account roles can order supplier products', (tester) async {
    for (final role in UserRole.values) {
      final service = serviceFor((_) async => http.Response('{}', 200));
      await tester.pumpWidget(
        AuthScope(
          user: AuthUser(
            id: 'user-${role.apiValue.toLowerCase()}',
            fullName: 'Test User',
            email: 'user@example.com',
            role: role,
          ),
          logout: () async {},
          updateUser: (_) {},
          api: service.api,
          child: MaterialApp(
            home: InventoryDetailsScreen(
              product: InventoryProduct.fromJson(product),
              productService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buy'), findsOneWidget, reason: role.apiValue);
    }
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
