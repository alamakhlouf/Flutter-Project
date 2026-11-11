import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:service_hub/app/app.dart';
import 'package:service_hub/design_system/app_colors.dart';
import 'package:service_hub/features/auth/services/auth_service.dart';

import 'support/memory_token_storage.dart';

void main() {
  testWidgets('ServiceHub starts with its brand theme', (tester) async {
    await tester.pumpWidget(
      ServiceHubApp(
        authService: AuthService(
          tokenStorage: MemoryTokenStorage(),
          httpClient: MockClient((request) async {
            fail('No request was expected');
          }),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in with your email and password.'), findsOneWidget);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme
          ?.colorScheme
          .primary,
      AppColors.primary,
    );
  });
}
