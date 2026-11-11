import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_hub/app/app.dart';
import 'package:service_hub/design_system/app_colors.dart';
import 'package:service_hub/features/auth/auth_keys.dart';
import 'package:service_hub/features/auth/services/auth_service.dart';

import 'support/memory_token_storage.dart';

void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  Map<String, Object?> userBody({
    String role = 'CUSTOMER',
    String name = 'A Customer',
  }) {
    return {
      'id': userId,
      'fullName': name,
      'email': 'person@example.com',
      'role': role,
      'phone': null,
      'profileImageUrl': null,
    };
  }

  AuthService serviceFor(http.Client client, {MemoryTokenStorage? storage}) {
    return AuthService(
      tokenStorage: storage ?? MemoryTokenStorage(),
      httpClient: client,
    );
  }

  Future<void> pumpApp(WidgetTester tester, AuthService service) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ServiceHubApp(authService: service));
  }

  testWidgets('a missing session opens the sign-in screen', (tester) async {
    final service = serviceFor(
      MockClient((request) async => fail('No request was expected')),
    );
    await pumpApp(tester, service);

    expect(find.text('Checking your session'), findsOneWidget);
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme
          ?.colorScheme
          .primary,
      AppColors.primary,
    );
    final buttonContext = tester.element(find.byKey(AuthKeys.loginSubmit));
    expect(
      Theme.of(buttonContext).filledButtonTheme.style?.backgroundColor
          ?.resolve(const <WidgetState>{}),
      AppColors.secondary,
    );
  });

  testWidgets('sign-in explains missing fields and reveals the password', (
    tester,
  ) async {
    final service = serviceFor(
      MockClient(
        (request) async => fail('Invalid forms must not call the API'),
      ),
    );
    await pumpApp(tester, service);
    await tester.pump();

    await tester.tap(find.byKey(AuthKeys.loginSubmit));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);

    await tester.enterText(find.byKey(AuthKeys.loginPassword), 'password123');
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();

    final field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(AuthKeys.loginPassword),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.obscureText, isFalse);
  });

  testWidgets('registration offers only mobile roles', (tester) async {
    final service = serviceFor(
      MockClient(
        (request) async => fail('Browsing registration must not call the API'),
      ),
    );
    await pumpApp(tester, service);
    await tester.pump();

    await tester.tap(find.byKey(AuthKeys.createAccount));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Service provider'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Administrator'), findsNothing);
    expect(find.text('ADMIN'), findsNothing);
  });

  testWidgets('a customer can sign in and log out', (tester) async {
    final storage = MemoryTokenStorage();
    final service = serviceFor(
      MockClient((request) async {
        return http.Response(
          jsonEncode({'token': 'customer-token', 'user': userBody()}),
          200,
        );
      }),
      storage: storage,
    );
    await pumpApp(tester, service);
    await tester.pump();

    await tester.enterText(
      find.byKey(AuthKeys.loginEmail),
      'person@example.com',
    );
    await tester.enterText(find.byKey(AuthKeys.loginPassword), 'password123');
    await tester.tap(find.byKey(AuthKeys.loginSubmit));
    await tester.pump();
    await tester.pump();

    expect(find.text('Hello, A Customer'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(storage.value, 'customer-token');

    await tester.tap(find.byKey(AuthKeys.logout));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(storage.value, isNull);
  });

  testWidgets('an administrator cannot use the mobile app', (tester) async {
    final service = serviceFor(
      MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': 'admin-token',
            'user': userBody(role: 'ADMIN', name: 'Ada Admin'),
          }),
          200,
        );
      }),
    );
    await pumpApp(tester, service);
    await tester.pump();

    await tester.enterText(
      find.byKey(AuthKeys.loginEmail),
      'admin@servicehub.local',
    );
    await tester.enterText(find.byKey(AuthKeys.loginPassword), 'password123');
    await tester.tap(find.byKey(AuthKeys.loginSubmit));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Administration will be available through the web backoffice.'),
      findsOneWidget,
    );
    expect(find.text('Hello, Ada Admin'), findsNothing);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('invalid credentials are shown and not submitted twice', (
    tester,
  ) async {
    var calls = 0;
    final response = Completer<http.Response>();
    final service = serviceFor(
      MockClient((request) async {
        calls += 1;
        return response.future;
      }),
    );
    await pumpApp(tester, service);
    await tester.pump();

    await tester.enterText(
      find.byKey(AuthKeys.loginEmail),
      'person@example.com',
    );
    await tester.enterText(find.byKey(AuthKeys.loginPassword), 'password123');
    await tester.tap(find.byKey(AuthKeys.loginSubmit));
    await tester.pump();
    await tester.tap(find.byKey(AuthKeys.loginSubmit));
    await tester.pump();
    expect(calls, 1);

    response.complete(
      http.Response(
        jsonEncode({'status': 401, 'message': 'Invalid email or password'}),
        401,
      ),
    );
    await tester.pump();

    expect(find.text('Invalid email or password'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('registration sends the selected supplier role', (tester) async {
    late Map<String, dynamic> body;
    final service = serviceFor(
      MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'token': 'supplier-token',
            'user': userBody(role: 'SUPPLIER', name: 'Sam Supplier'),
          }),
          200,
        );
      }),
    );
    await pumpApp(tester, service);
    await tester.pump();
    await tester.tap(find.byKey(AuthKeys.createAccount));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byKey(AuthKeys.registerName), 'Sam Supplier');
    await tester.enterText(
      find.byKey(AuthKeys.registerEmail),
      'sam@example.com',
    );
    await tester.enterText(
      find.byKey(AuthKeys.registerPassword),
      'password123',
    );
    await tester.enterText(find.byKey(AuthKeys.registerConfirm), 'password123');
    await tester.tap(find.text('Supplier'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(AuthKeys.registerSubmit));
    await tester.tap(find.byKey(AuthKeys.registerSubmit));
    await tester.pump();
    await tester.pump();

    expect(body['role'], 'SUPPLIER');
    expect(body.containsKey('confirmPassword'), isFalse);
    expect(find.text('Hello, Sam Supplier'), findsOneWidget);
    expect(find.text('Supplier'), findsOneWidget);
  });
}
