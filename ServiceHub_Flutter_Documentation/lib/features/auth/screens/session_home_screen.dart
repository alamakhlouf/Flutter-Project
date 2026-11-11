import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/models/auth_user.dart';
import '../../profile/profile_keys.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/services/profile_service.dart';
import '../../services/models/service_model.dart';
import '../../services/screens/my_services_screen.dart';
import '../../services/screens/service_details_screen.dart';
import '../../services/screens/service_form_screen.dart';
import '../../services/screens/services_catalog_screen.dart';
import '../../services/services_keys.dart';
import '../auth_keys.dart';
import '../auth_scope.dart';
import '../widgets/auth_widgets.dart';

class SessionHomeScreen extends StatelessWidget {
  const SessionHomeScreen({super.key});

  Route<void> _homeRoute() {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.home),
      builder: (_) => const _AccountHome(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: AppRoutes.home,
      onGenerateInitialRoutes: (navigator, initialRoute) => [_homeRoute()],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.profile:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ProfileScreen(),
            );
          case AppRoutes.editProfile:
            final args = settings.arguments;
            if (args is Map<String, dynamic> &&
                args['user'] is AuthUser &&
                args['profileService'] is ProfileService) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => EditProfileScreen(
                  user: args['user'] as AuthUser,
                  profileService: args['profileService'] as ProfileService,
                ),
              );
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ProfileScreen(),
            );
          case AppRoutes.servicesCatalog:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ServicesCatalogScreen(),
            );
          case AppRoutes.serviceDetails:
            final service = settings.arguments is ServiceModel
                ? settings.arguments as ServiceModel
                : null;
            final serviceId = settings.arguments is String
                ? settings.arguments as String
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ServiceDetailsScreen(
                service: service,
                serviceId: serviceId,
              ),
            );
          case AppRoutes.myServices:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const MyServicesScreen(),
            );
          case AppRoutes.createService:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ServiceFormScreen(),
            );
          case AppRoutes.editService:
            final service = settings.arguments is ServiceModel
                ? settings.arguments as ServiceModel
                : null;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ServiceFormScreen(service: service),
            );
          default:
            return _homeRoute();
        }
      },
    );
  }
}

class _AccountHome extends StatelessWidget {
  const _AccountHome();

  @override
  Widget build(BuildContext context) {
    final scope = AuthScope.of(context);
    final user = scope.user;
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey(AppRoutes.home),
      appBar: AppBar(title: const Text('ServiceHub')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Hello, ${user.fullName}',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You are signed in to ServiceHub.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    Text('Email', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(user.email, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Text('Role', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(user.role.label, style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: ServicesKeys.openCatalog,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Browse Services Catalog'),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.servicesCatalog),
            ),
            if (user.role == UserRole.provider) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                key: ServicesKeys.openMyServices,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                ),
                icon: const Icon(Icons.home_repair_service_outlined),
                label: const Text('Manage My Services'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.myServices),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              key: ProfileKeys.open,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.profile),
              child: const Text('My profile'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: AuthKeys.logout,
              onPressed: () async {
                final confirmed = await confirmLogout(context);
                if (!confirmed || !context.mounted) return;
                await scope.logout();
              },
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
