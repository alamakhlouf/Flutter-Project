import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/inventory/services/inventory_service.dart';

void main() {
  test('inventory creation sends the selected image data', () async {
    late http.Request sent;
    const imageUrl = 'data:image/jpeg;base64,dGVzdA==';
    final service = InventoryService(
      api: ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'id': 'inventory-1',
              'providerId': 'provider-1',
              'name': 'Cleaning supplies',
              'description': 'Supplies for cleaning',
              'quantity': 2,
              'unit': 'packs',
              'imageUrl': imageUrl,
              'catalogCategory': 'Cleaning',
              'catalogPrice': 4.25,
            }),
            200,
          );
        }),
        readToken: () async => 'test-token',
      ),
    );

    final item = await service.createInventoryItem(
      name: 'Cleaning supplies',
      description: 'Supplies for cleaning',
      quantity: 2,
      unit: 'packs',
      catalogCategory: 'Cleaning',
      catalogPrice: 4.25,
      imageUrl: imageUrl,
    );

    expect(sent.url.path, '/api/inventory');
    expect(jsonDecode(sent.body)['imageUrl'], imageUrl);
    expect(jsonDecode(sent.body)['catalogCategory'], 'Cleaning');
    expect(jsonDecode(sent.body)['catalogPrice'], 4.25);
    expect(item.imageUrl, imageUrl);
    expect(item.catalogCategory, 'Cleaning');
    expect(item.catalogPrice, 4.25);
  });
}
