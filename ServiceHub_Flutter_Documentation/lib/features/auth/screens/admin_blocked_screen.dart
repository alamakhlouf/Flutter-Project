import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';
import '../auth_keys.dart';
import '../widgets/auth_widgets.dart';

class AdminBlockedScreen extends StatelessWidget {
  const AdminBlockedScreen({
    required this.email,
    required this.onLogout,
    super.key,
  });

  final String email;
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
                    'Mobile access is unavailable',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Administration will be available through the web backoffice.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Signed in as $email. This administrator account cannot use ServiceHub on mobile.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
