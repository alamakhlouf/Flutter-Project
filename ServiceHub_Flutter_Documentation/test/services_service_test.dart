import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/services/models/service_model.dart';
import 'package:service_hub/features/services/services/services_service.dart';

void main() {
  const serviceId = '11111111-2222-3333-4444-555555555555';
  const providerId = '99999999-8888-7777-6666-555555555555';

  final sampleServiceJson = <String, dynamic>{
    'id': serviceId,
    'providerId': providerId,
    'title': 'Deep Cleaning',
    'description': 'Thorough home deep cleaning service.',
    'category': ServiceCategory.cleaning,
    'price': 120.0,
    'priceDescription': 'per session',
    'location': 'Algiers',
    'imageUrl': 'https://example.com/clean.png',
    'isActive': true,
    'providerName': 'CleanPro Services',
    'providerEmail': 'contact@cleanpro.dz',
    'providerPhone': '+213555010203',
  };

  ServicesService buildService(MockClientHandler handler) {
    return ServicesService(
      api: ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient(handler),
        readToken: () async => 'test-jwt-token',
      ),
    );
  }

  test('fetchCatalog sends GET /api/services with query parameters', () async {
    late Uri requestUri;
    final service = buildService((request) async {
      requestUri = request.url;
      return http.Response(
        jsonEncode({
          'content': [sampleServiceJson],
        }),
        200,
      );
    });

    final results = await service.fetchCatalog(
      search: 'Deep',
      category: ServiceCategory.cleaning,
      maxPrice: 150.0,
      location: 'Algiers',
    );

    expect(requestUri.path, '/api/services');
    expect(requestUri.queryParameters['search'], 'Deep');
    expect(requestUri.queryParameters['category'], 'Cleaning');
    expect(requestUri.queryParameters['maxPrice'], '150.0');
    expect(requestUri.queryParameters['location'], 'Algiers');
    expect(results.length, 1);
    expect(results.first.title, 'Deep Cleaning');
    expect(results.first.category, ServiceCategory.cleaning);
  });

  test('fetchMyServices sends authenticated GET /api/services/my', () async {
    late String path;
    late String? authHeader;
    final service = buildService((request) async {
      path = request.url.path;
      authHeader = request.headers['authorization'];
      return http.Response(
        jsonEncode({
          'content': [sampleServiceJson],
        }),
        200,
      );
    });

    final results = await service.fetchMyServices();

    expect(path, '/api/services/my');
    expect(authHeader, 'Bearer test-jwt-token');
    expect(results.length, 1);
    expect(results.first.providerId, providerId);
  });

  test('getServiceById sends GET /api/services/{id}', () async {
    late String path;
    final service = buildService((request) async {
      path = request.url.path;
      return http.Response(jsonEncode(sampleServiceJson), 200);
    });

    final result = await service.getServiceById(serviceId);

    expect(path, '/api/services/$serviceId');
    expect(result.id, serviceId);
    expect(result.title, 'Deep Cleaning');
  });

  test('createService sends POST /api/services with request body', () async {
    late String method;
    late Map<String, dynamic> body;
    final service = buildService((request) async {
      method = request.method;
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode(sampleServiceJson), 201);
    });

    final created = await service.createService(
      title: 'Deep Cleaning',
      description: 'Thorough home deep cleaning service.',
      category: ServiceCategory.cleaning,
      price: 120.0,
      priceDescription: 'per session',
      location: 'Algiers',
      imageUrl: 'https://example.com/clean.png',
      isActive: true,
    );

    expect(method, 'POST');
    expect(body['title'], 'Deep Cleaning');
    expect(body['category'], 'Cleaning');
    expect(body['price'], 120.0);
    expect(created.id, serviceId);
  });

  test('updateService sends PUT /api/services/{id}', () async {
    late String method;
    late String path;
    late Map<String, dynamic> body;
    final service = buildService((request) async {
      method = request.method;
      path = request.url.path;
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(jsonEncode(sampleServiceJson), 200);
    });

    final updated = await service.updateService(
      id: serviceId,
      title: 'Updated Title',
      description: 'Updated Description longer text.',
      category: ServiceCategory.cleaning,
      price: 130.0,
      priceDescription: 'per session',
      location: 'Oran',
      imageUrl: 'https://example.com/clean2.png',
      isActive: true,
    );

    expect(method, 'PUT');
    expect(path, '/api/services/$serviceId');
    expect(body['title'], 'Updated Title');
    expect(updated.id, serviceId);
  });

  test('toggleServiceActive sends PATCH /api/services/{id}/status', () async {
    late String method;
    late String path;
    late Map<String, dynamic> body;
    final service = buildService((request) async {
      method = request.method;
      path = request.url.path;
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({...sampleServiceJson, 'isActive': false}),
        200,
      );
    });

    final toggled = await service.toggleServiceActive(
      id: serviceId,
      isActive: false,
    );

    expect(method, 'PATCH');
    expect(path, '/api/services/$serviceId/status');
    expect(body['isActive'], isFalse);
    expect(toggled.isActive, isFalse);
  });

  test('deleteService sends DELETE /api/services/{id}', () async {
    late String method;
    late String path;
    final service = buildService((request) async {
      method = request.method;
      path = request.url.path;
      return http.Response('', 204);
    });

    await service.deleteService(serviceId);

    expect(method, 'DELETE');
    expect(path, '/api/services/$serviceId');
  });
}
