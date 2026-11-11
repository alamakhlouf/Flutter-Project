import 'package:flutter/material.dart';

import '../auth_keys.dart';
import '../widgets/auth_widgets.dart';

class SessionErrorScreen extends StatelessWidget {
  const SessionErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onLogout,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const BrandMark(),
                  const SizedBox(height: 20),
                  Text(
                    'Session unavailable',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  AuthErrorBanner(message: message),
                  const SizedBox(height: 20),
                  AuthSubmitButton(
                    key: AuthKeys.retrySession,
                    label: 'Try again',
                    loading: false,
                    onPressed: onRetry,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: AuthKeys.logout,
                    onPressed: () async {
                      final confirmed = await confirmLogout(context);
                      if (!confirmed || !context.mounted) return;
                      await onLogout();
                    },
                    child: const Text('Log out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
