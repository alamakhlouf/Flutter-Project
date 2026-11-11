import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/core/network/api_exception.dart';
import 'package:service_hub/features/auth/models/auth_user.dart';
import 'package:service_hub/features/auth/services/auth_service.dart';

import 'support/memory_token_storage.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  Map<String, Object?> userBody({String role = 'CUSTOMER'}) {
    return {
      'id': userId,
      'fullName': 'A Customer',
      'email': 'person@example.com',
      'role': role,
      'phone': null,
      'profileImageUrl': null,
    };
  }

  test(
    'login stores the token and does not send an authorization header',
    () async {
      final storage = MemoryTokenStorage();
      late http.Request sent;
      final service = AuthService(
        tokenStorage: storage,
        httpClient: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({'token': 'session-token', 'user': userBody()}),
            200,
          );
        }),
      );

      final user = await service.login(
        email: ' person@example.com ',
        password: 'password123',
      );

      expect(user.role, UserRole.customer);
      expect(user.id, userId);
      expect(storage.value, 'session-token');
      expect(sent.url.path, '/api/auth/login');
      expect(sent.headers.containsKey('authorization'), isFalse);
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['email'], 'person@example.com');
      expect(body['password'], 'password123');
      service.dispose();
    },
  );

  test('invalid credentials stay signed out', () async {
    final storage = MemoryTokenStorage();
    var expired = false;
    final service = AuthService(
      tokenStorage: storage,
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 401,
            'message': 'Invalid email or password',
            'path': '/api/auth/login',
          }),
          401,
        );
      }),
    );
    service.onSessionExpired = () => expired = true;

    await expectLater(
      service.login(email: 'person@example.com', password: 'password123'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Invalid email or password',
        ),
      ),
    );
    expect(storage.value, isNull);
    expect(expired, isFalse);
    service.dispose();
  });

  test(
    'registration sends the mobile role and omits the confirmation',
    () async {
      final storage = MemoryTokenStorage();
      late Map<String, dynamic> body;
      final service = AuthService(
        tokenStorage: storage,
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'token': 'new-token',
              'user': userBody(role: 'PROVIDER'),
            }),
            200,
          );
        }),
      );

      final user = await service.register(
        fullName: ' Pat Provider ',
        email: 'pat@example.com',
        password: 'password123',
        role: UserRole.provider,
      );

      expect(user.role, UserRole.provider);
      expect(body['fullName'], 'Pat Provider');
      expect(body['role'], 'PROVIDER');
      expect(body.containsKey('confirmPassword'), isFalse);
      expect(storage.value, 'new-token');
      service.dispose();
    },
  );

  test('administrator registration never reaches the network', () async {
    final service = AuthService(
      tokenStorage: MemoryTokenStorage(),
      httpClient: MockClient((request) async {
        fail('ADMIN registration must be blocked in the app');
      }),
    );

    await expectLater(
      service.register(
        fullName: 'Admin',
        email: 'admin@example.com',
        password: 'password123',
        role: UserRole.admin,
      ),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 403),
      ),
    );
    service.dispose();
  });

  test('restore reads the current user with the stored token', () async {
    final storage = MemoryTokenStorage()..value = 'saved-token';
    late http.Request sent;
    final service = AuthService(
      tokenStorage: storage,
      httpClient: MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode(userBody()), 200);
      }),
    );

    final user = await service.restore();

    expect(user?.email, 'person@example.com');
    expect(sent.headers['authorization'], 'Bearer saved-token');
    expect(sent.url.path, '/api/auth/me');
    service.dispose();
  });

  test('an expired token is cleared and ends the session', () async {
    final storage = MemoryTokenStorage()..value = 'expired-token';
    var expired = false;
    final service = AuthService(
      tokenStorage: storage,
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({'status': 401, 'message': 'Authentication is required'}),
          401,
        );
      }),
    );
    service.onSessionExpired = () => expired = true;

    expect(await service.restore(), isNull);
    expect(storage.value, isNull);
    expect(service.currentUser, isNull);
    expect(expired, isTrue);
    service.dispose();
  });

  test('logout deletes the stored token', () async {
    final storage = MemoryTokenStorage()..value = 'saved-token';
    final service = AuthService(
      tokenStorage: storage,
      httpClient: MockClient((request) async => http.Response('{}', 200)),
    );
    service.currentUser = AuthUser.fromJson(userBody());

    await service.logout();

    expect(storage.value, isNull);
    expect(service.currentUser, isNull);
    service.dispose();
  });

  test('a connection failure stays understandable', () async {
    final service = AuthService(
      tokenStorage: MemoryTokenStorage(),
      httpClient: MockClient((request) async {
        throw http.ClientException('Connection refused');
      }),
    );

    await expectLater(
      service.login(email: 'person@example.com', password: 'password123'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Unable to reach the server. Check your connection and try again.',
        ),
      ),
    );
    service.dispose();
  });
}
