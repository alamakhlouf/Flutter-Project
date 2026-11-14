import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../profile_keys.dart';
import '../services/profile_service.dart';
import '../widgets/profile_widgets.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileService? _service;
  AuthUser? _user;
  var _loading = true;
  String? _error;
  String? _success;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_service != null) return;
    _service = ProfileService(AuthScope.of(context).api);
    _load();
  }

  Future<void> _load() async {
    if (mounted && !_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = await _service!.load();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
      AuthScope.of(context).updateUser(user);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load your profile. Try again.';
      });
    }
  }

  Future<void> _edit() async {
    final user = _user;
    final service = _service;
    if (user == null || service == null) return;
    final updated = await Navigator.of(context).push<AuthUser>(
      MaterialPageRoute<AuthUser>(
        settings: const RouteSettings(name: AppRoutes.editProfile),
        builder: (_) => EditProfileScreen(user: user, profileService: service),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _user = updated;
      _success = 'Profile updated successfully.';
      _error = null;
    });
    AuthScope.of(context).updateUser(updated);
  }

  Future<void> _logout() async {
    final confirmed = await confirmLogout(context);
    if (!confirmed || !mounted) return;
    await AuthScope.of(context).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      key: const ValueKey(AppRoutes.profile),
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _loading
            ? const _ProfileLoading()
            : user == null
                ? _ProfileError(
                    message: _error ?? 'Unable to load your profile.',
                    onRetry: _load,
                    onLogout: _logout,
                  )
                : _ProfileBody(
                    user: user,
                    error: _error,
                    success: _success,
                    onEdit: _edit,
                    onLogout: _logout,
                    onRetry: _load,
                    onMyReports: () =>
                        Navigator.of(context).pushNamed(AppRoutes.myReports),
                    onMyActivity: () =>
                        Navigator.of(context).pushNamed(AppRoutes.myActivity),
                  ),
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading profile details...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AuthErrorBanner(message: message),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: ProfileKeys.retry,
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: ProfileKeys.logout,
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.error,
    required this.success,
    required this.onEdit,
    required this.onLogout,
    required this.onRetry,
    required this.onMyReports,
    required this.onMyActivity,
  });

  final AuthUser user;
  final String? error;
  final String? success;
  final VoidCallback onEdit;
  final Future<void> Function() onLogout;
  final VoidCallback onRetry;
  final VoidCallback onMyReports;
  final VoidCallback onMyActivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = user.phone?.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Hero Card Header
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              ProfileAvatar(
                name: user.fullName,
                imageUrl: user.profileImageUrl,
                size: 96,
              ),
              const SizedBox(height: 16),
              Text(
                user.fullName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _RoleBadge(role: user.role),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (success != null) ...[
          ProfileNotice(
            message: success!,
            color: AppColors.success,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 16),
        ],

        if (error != null) ...[
          AuthErrorBanner(message: error!),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ProfileKeys.retry,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Section: Personal / Business Details
        _SectionCard(
          title: _sectionTitle(user.role),
          icon: _sectionIcon(user.role),
          children: [
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: _nameLabel(user.role),
              value: user.fullName,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.border),
            ),
            _DetailRow(
              icon: Icons.email_outlined,
              label: 'Email Address',
              value: user.email,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: AppColors.border),
            ),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              value: phone == null || phone.isEmpty ? 'Not provided' : phone,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section: Account & Actions
        _SectionCard(
          title: 'Account Settings',
          icon: Icons.tune_rounded,
          children: [
            _MenuTile(
              key: ProfileKeys.edit,
              icon: Icons.edit_outlined,
              iconBgColor: AppColors.primary.withOpacity(0.1),
              iconColor: AppColors.primary,
              title: 'Edit Profile',
              subtitle: 'Update details and profile photo',
              onTap: onEdit,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(height: 1, color: AppColors.border),
            ),
            if (user.role == UserRole.admin) ...[
              _MenuTile(
                icon: Icons.admin_panel_settings_outlined,
                iconBgColor: AppColors.primary.withOpacity(0.12),
                iconColor: AppColors.primary,
                title: 'Admin Moderation',
                subtitle: 'Review reported users & services',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.adminReports),
              ),
            ] else ...[
              _MenuTile(
                icon: Icons.receipt_long_outlined,
                iconBgColor: AppColors.tertiary.withOpacity(0.12),
                iconColor: AppColors.warning,
                title: 'My Activity',
                subtitle: 'View bookings, orders & registrations',
                onTap: onMyActivity,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _MenuTile(
                icon: Icons.outlined_flag,
                iconBgColor: AppColors.info.withOpacity(0.12),
                iconColor: AppColors.info,
                title: 'My Reports',
                subtitle: 'Track status of your submitted reports',
                onTap: onMyReports,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _MenuTile(
                icon: Icons.favorite_border,
                iconBgColor: AppColors.error.withOpacity(0.12),
                iconColor: AppColors.error,
                title: 'Favorite Services',
                subtitle: 'View your saved services',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.favoriteServices),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _MenuTile(
                icon: Icons.favorite,
                iconBgColor: AppColors.error.withOpacity(0.12),
                iconColor: AppColors.error,
                title: 'Favorite Products',
                subtitle: 'View your saved supplier products',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.favoriteProducts),
              ),
              if (user.role == UserRole.provider) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _MenuTile(
                  icon: Icons.calendar_month_outlined,
                  iconBgColor: AppColors.primary.withOpacity(0.12),
                  iconColor: AppColors.primary,
                  title: 'Provider Calendar',
                  subtitle: 'View monthly schedule, bookings & unavailable dates',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.providerCalendar),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                _MenuTile(
                  icon: Icons.schedule_outlined,
                  iconBgColor: AppColors.primary.withOpacity(0.12),
                  iconColor: AppColors.primary,
                  title: 'Availability & Schedule',
                  subtitle: 'Set working hours, breaks & time-off',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.availabilityManagement),
                ),
              ],
            ],
          ],
        ),

        const SizedBox(height: 24),

        // Logout Section
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.error.withOpacity(0.25)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              key: ProfileKeys.logout,
              borderRadius: BorderRadius.circular(20),
              onTap: onLogout,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Log Out',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign out of your account on this device',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _sectionTitle(UserRole role) {
    return switch (role) {
      UserRole.customer => 'Personal Details',
      UserRole.provider => 'Professional Details',
      UserRole.supplier => 'Business Details',
      UserRole.admin => 'Account Details',
    };
  }

  static IconData _sectionIcon(UserRole role) {
    return switch (role) {
      UserRole.customer => Icons.person_outline_rounded,
      UserRole.provider => Icons.work_outline_rounded,
      UserRole.supplier => Icons.storefront_outlined,
      UserRole.admin => Icons.admin_panel_settings_outlined,
    };
  }

  static String _nameLabel(UserRole role) {
    return role == UserRole.supplier ? 'Business Name' : 'Full Name';
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final icon = switch (role) {
      UserRole.customer => Icons.person_outline_rounded,
      UserRole.provider => Icons.handyman_outlined,
      UserRole.supplier => Icons.storefront_outlined,
      UserRole.admin => Icons.admin_panel_settings_outlined,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            role.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.neutral,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
