import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/app/app.dart';
import 'package:service_hub/features/auth/auth_keys.dart';
import 'package:service_hub/features/auth/services/auth_service.dart';
import 'package:service_hub/features/profile/profile_keys.dart';

import 'support/memory_token_storage.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  Map<String, Object?> user({
    required String role,
    required String name,
    String? phone,
    String email = 'person@example.com',
  }) {
    return {
      'id': userId,
      'fullName': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImageUrl': null,
    };
  }

  Map<String, Object?> authBody({
    required String role,
    required String name,
    String? phone,
  }) {
    return {
      'token': 'session-token',
      'user': user(role: role, name: name, phone: phone),
    };
  }

  Future<void> signIn(
    WidgetTester tester, {
    required http.Client client,
  }) async {
    tester.view.physicalSize = const Size(500, 1600);
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
    await tester.enterText(
      find.byKey(AuthKeys.loginEmail),
      'person@example.com',
    );
    await tester.enterText(find.byKey(AuthKeys.loginPassword), 'password123');
    await tester.tap(find.byKey(AuthKeys.loginSubmit));
    await tester.pump();
    await tester.pump();
  }

  Future<void> openProfile(WidgetTester tester) async {
    await tester.tap(find.byKey(ProfileKeys.open));
    await tester.pumpAndSettle();
  }

  testWidgets('profile loads from the backend and keeps the role fixed', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    final client = MockClient((request) async {
      if (request.url.path == '/api/auth/login') {
        return http.Response(
          jsonEncode(
            authBody(role: 'CUSTOMER', name: 'A Customer', phone: null),
          ),
          200,
        );
      }
      if (request.method == 'GET' && request.url.path == '/api/users/me') {
        return http.Response(
          jsonEncode(
            user(role: 'CUSTOMER', name: 'A Customer', phone: '+213555010101'),
          ),
          200,
        );
      }
      if (request.method == 'PUT' && request.url.path == '/api/users/me') {
        saved = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(
            user(
              role: 'CUSTOMER',
              name: saved!['fullName'] as String,
              phone: saved!['phone'] as String?,
            ),
          ),
          200,
        );
      }
      return http.Response('{"message":"Not found"}', 404);
    });

    await signIn(tester, client: client);
    await openProfile(tester);

    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('+213555010101'), findsOneWidget);
    expect(find.text('Role: Customer'), findsOneWidget);
    expect(find.text('Administrator'), findsNothing);

    await tester.tap(find.byKey(ProfileKeys.edit));
    await tester.pumpAndSettle();

    expect(find.text('Role cannot be changed.'), findsOneWidget);
    expect(find.text('Email cannot be changed.'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNothing);

    await tester.enterText(find.byKey(ProfileKeys.name), ' ');
    await tester.enterText(find.byKey(ProfileKeys.imageUrl), 'not-a-link');
    await tester.tap(find.byKey(ProfileKeys.save));
    await tester.pump();

    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Enter an http or https image link.'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(find.byKey(ProfileKeys.name), 'Updated Customer');
    await tester.enterText(find.byKey(ProfileKeys.phone), '+213555019999');
    await tester.enterText(find.byKey(ProfileKeys.imageUrl), '');
    await tester.tap(find.byKey(ProfileKeys.save));
    await tester.pumpAndSettle();

    expect(saved?.containsKey('role'), isFalse);
    expect(saved?.containsKey('email'), isFalse);
    expect(saved?['fullName'], 'Updated Customer');
    expect(saved?['phone'], '+213555019999');
    expect(find.text('Profile updated.'), findsOneWidget);
    expect(find.text('Updated Customer'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Hello, Updated Customer'), findsOneWidget);
  });

  testWidgets('a provider sees professional details', (tester) async {
    await signIn(
      tester,
      client: MockClient((request) async {
        final body = user(role: 'PROVIDER', name: 'Pat Provider', phone: null);
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({'token': 'session-token', 'user': body}),
            200,
          );
        }
        return http.Response(jsonEncode(body), 200);
      }),
    );
    await openProfile(tester);

    expect(find.text('Professional details'), findsOneWidget);
    expect(find.text('Role: Service provider'), findsOneWidget);
    expect(find.text('Administrator'), findsNothing);
  });

  testWidgets('a supplier sees business details', (tester) async {
    await signIn(
      tester,
      client: MockClient((request) async {
        final body = user(role: 'SUPPLIER', name: 'Sam Supplier', phone: null);
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({'token': 'session-token', 'user': body}),
            200,
          );
        }
        return http.Response(jsonEncode(body), 200);
      }),
    );
    await openProfile(tester);

    expect(find.text('Business details'), findsOneWidget);
    expect(find.text('Business name'), findsOneWidget);
    expect(find.text('Role: Supplier'), findsOneWidget);
  });

  testWidgets('a profile load error can be retried and the user can log out', (
    tester,
  ) async {
    var loads = 0;
    await signIn(
      tester,
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode(
              authBody(role: 'CUSTOMER', name: 'A Customer', phone: null),
            ),
            200,
          );
        }
        loads += 1;
        if (loads == 1) {
          return http.Response(
            jsonEncode({'message': 'Profile is unavailable'}),
            500,
          );
        }
        return http.Response(
          jsonEncode(user(role: 'CUSTOMER', name: 'A Customer', phone: null)),
          200,
        );
      }),
    );

    await openProfile(tester);
    expect(find.text('Profile is unavailable'), findsOneWidget);

    await tester.tap(find.byKey(ProfileKeys.retry));
    await tester.pump();
    await tester.pump();
    expect(find.text('Personal details'), findsOneWidget);

    await tester.tap(find.byKey(ProfileKeys.logout));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
