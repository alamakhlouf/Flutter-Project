import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/auth/auth_scope.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/inventory/models/product_order_model.dart';
import 'package:service_hub/features/inventory/screens/product_orders_screen.dart';
import 'package:service_hub/features/inventory/services/product_order_service.dart';

void main() {
  Map<String, dynamic> orderJson({String status = 'PENDING'}) => {
    'id': 'order-1',
    'customerId': 'customer-1',
    'customerName': 'Test customer',
    'supplierId': 'supplier-1',
    'supplierName': 'Test supplier',
    'totalAmount': 12.5,
    'status': status,
    'items': [
      {
        'id': 'line-1',
        'productId': 'product-1',
        'productName': 'Soap',
        'unitPrice': 12.5,
        'quantity': 1,
        'lineTotal': 12.5,
      },
    ],
    'createdAt': '2025-02-12T14:30:00',
  };

  test('fetches and parses the signed-in user order list', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.url.path, '/api/orders/my');
        return http.Response(jsonEncode([orderJson()]), 200);
      }),
      readToken: () async => 'test-token',
    );

    final orders = await ProductOrderService(api: api).fetchMyOrders();

    expect(orders, hasLength(1));
    expect(orders.single.supplierName, 'Test supplier');
    expect(orders.single.items.single.productName, 'Soap');
  });

  testWidgets('supplier can accept an incoming order', (tester) async {
    http.Request? statusRequest;
    final api = ApiClient(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        statusRequest = request;
        return http.Response(jsonEncode(orderJson(status: 'ACCEPTED')), 200);
      }),
      readToken: () async => 'test-token',
    );
    final order = ProductOrderModel.fromJson(orderJson());

    await tester.pumpWidget(
      AuthScope(
        user: const AuthUser(
          id: 'supplier-1',
          fullName: 'Test supplier',
          email: 'supplier@example.com',
          role: UserRole.supplier,
        ),
        logout: () async {},
        updateUser: (_) {},
        api: api,
        child: MaterialApp(
          home: ProductOrderDetailsScreen(
            order: order,
            isSupplier: true,
            orderService: ProductOrderService(api: api),
          ),
        ),
      ),
    );

    expect(find.text('Test customer'), findsOneWidget);
    await tester.tap(find.text('Accept order'));
    await tester.pumpAndSettle();

    expect(statusRequest?.method, 'PATCH');
    expect(statusRequest?.url.path, '/api/orders/order-1/status');
    expect(jsonDecode(statusRequest!.body), {'status': 'ACCEPTED'});
    expect(find.text('ACCEPTED'), findsOneWidget);
  });
}
