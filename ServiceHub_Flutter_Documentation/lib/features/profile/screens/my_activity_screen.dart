import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';

class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AuthScope.of(context).user.role;
    final activities = switch (role) {
      UserRole.customer => const [
        _Activity(
          title: 'Service bookings',
          subtitle: 'Track requests and appointments with providers.',
          icon: Icons.home_repair_service_outlined,
          route: AppRoutes.bookingsList,
        ),
        _Activity(
          title: 'Product orders',
          subtitle: 'View items you ordered and their progress.',
          icon: Icons.shopping_bag_outlined,
          route: AppRoutes.productOrders,
        ),
        _Activity(
          title: 'Workshop registrations',
          subtitle: 'See workshops you enrolled in.',
          icon: Icons.school_outlined,
          route: AppRoutes.myWorkshopRegistrations,
        ),
      ],
      UserRole.provider => const [
        _Activity(
          title: 'Incoming service requests',
          subtitle: 'Review, accept, and update customer bookings.',
          icon: Icons.inbox_outlined,
          route: AppRoutes.bookingsList,
        ),
        _Activity(
          title: 'Product orders',
          subtitle: 'Track orders you placed with suppliers.',
          icon: Icons.shopping_bag_outlined,
          route: AppRoutes.productOrders,
        ),
        _Activity(
          title: 'Workshop registrations',
          subtitle: 'See workshops you enrolled in.',
          icon: Icons.school_outlined,
          route: AppRoutes.myWorkshopRegistrations,
        ),
        _Activity(
          title: 'My organized workshops',
          subtitle: 'Manage workshops you host.',
          icon: Icons.event_note_outlined,
          route: AppRoutes.myWorkshops,
        ),
      ],
      UserRole.supplier => const [
        _Activity(
          title: 'Incoming product orders',
          subtitle: 'Review customer orders and update fulfillment status.',
          icon: Icons.inbox_outlined,
          route: AppRoutes.productOrders,
        ),
      ],
      UserRole.admin => const [],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('My activity')),
      body: activities.isEmpty
          ? const Center(
              child: Text(
                'Activity is available to customer, provider, and supplier accounts.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Your services, orders, and registrations in one place.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                for (final activity in activities) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: AppColors.surface,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.08,
                        ),
                        foregroundColor: AppColors.primary,
                        child: Icon(activity.icon),
                      ),
                      title: Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(activity.subtitle),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context).pushNamed(activity.route),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Activity {
  const _Activity({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
