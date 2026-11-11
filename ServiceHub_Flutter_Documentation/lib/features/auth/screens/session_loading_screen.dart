import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';
import '../widgets/auth_widgets.dart';

class SessionLoadingScreen extends StatelessWidget {
  const SessionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(),
                const SizedBox(height: 20),
                Text('ServiceHub', style: theme.textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Checking your session',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
