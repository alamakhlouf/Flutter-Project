import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_client.dart';
import 'package:service_hub/features/profile/services/profile_service.dart';

void main() {
  const user = {
    'id': '11111111-1111-1111-1111-111111111111',
    'fullName': 'Sam Supplier',
    'email': 'sam@example.com',
    'role': 'SUPPLIER',
    'phone': '+213555010101',
    'profileImageUrl': null,
  };

  test('update sends name, phone, and image link only', () async {
    late Map<String, dynamic> body;
    late String? authorization;
    final service = ProfileService(
      ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          authorization = request.headers['authorization'];
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(user), 200);
        }),
        readToken: () async => 'token',
      ),
    );

    final updated = await service.update(
      fullName: ' Sam Supplier ',
      phone: '   ',
      profileImageUrl: ' https://example.com/a.jpg ',
    );

    expect(updated.role.name, 'supplier');
    expect(authorization, 'Bearer token');
    expect(body['fullName'], 'Sam Supplier');
    expect(body['phone'], isNull);
    expect(body['profileImageUrl'], 'https://example.com/a.jpg');
    expect(body.containsKey('role'), isFalse);
    expect(body.containsKey('email'), isFalse);
    expect(body.keys.toList(), ['fullName', 'phone', 'profileImageUrl']);
  });

  test('load reads the signed-in profile', () async {
    late String path;
    final service = ProfileService(
      ApiClient(
        baseUrl: 'http://localhost:8080',
        client: MockClient((request) async {
          path = request.url.path;
          return http.Response(jsonEncode(user), 200);
        }),
        readToken: () async => 'token',
      ),
    );

    final loaded = await service.load();

    expect(path, '/api/users/me');
    expect(loaded.fullName, 'Sam Supplier');
    expect(loaded.phone, '+213555010101');
    expect(loaded.email, 'sam@example.com');
  });
}
