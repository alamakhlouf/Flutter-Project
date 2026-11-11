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
      _success = 'Profile updated.';
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
      appBar: AppBar(title: const Text('My profile')),
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
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Loading your profile',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.textSecondary),
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
        const SizedBox(height: 20),
        FilledButton(
          key: ProfileKeys.retry,
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: ProfileKeys.logout,
          onPressed: onLogout,
          child: const Text('Log out'),
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
  });

  final AuthUser user;
  final String? error;
  final String? success;
  final VoidCallback onEdit;
  final Future<void> Function() onLogout;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = user.phone?.trim();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ProfileAvatar(
            name: user.fullName,
            imageUrl: user.profileImageUrl,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          _intro(user.role),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Center(child: _RoleLabel(role: user.role)),
        const SizedBox(height: 20),
        if (success != null) ...[
          ProfileNotice(
            message: success!,
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 16),
        ],
        if (error != null) ...[
          AuthErrorBanner(message: error!),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: ProfileKeys.retry,
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
                Text(
                  _sectionTitle(user.role),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _Detail(label: _nameLabel(user.role), value: user.fullName),
                const SizedBox(height: 16),
                _Detail(label: 'Email', value: user.email),
                const SizedBox(height: 16),
                _Detail(
                  label: 'Phone',
                  value: phone == null || phone.isEmpty ? 'Not added' : phone,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: ProfileKeys.edit,
          onPressed: onEdit,
          child: const Text('Edit profile'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: ProfileKeys.logout,
          onPressed: onLogout,
          child: const Text('Log out'),
        ),
      ],
    );
  }

  static String _sectionTitle(UserRole role) {
    return switch (role) {
      UserRole.customer => 'Personal details',
      UserRole.provider => 'Professional details',
      UserRole.supplier => 'Business details',
      UserRole.admin => 'Account details',
    };
  }

  static String _nameLabel(UserRole role) {
    return role == UserRole.supplier ? 'Business name' : 'Full name';
  }

  static String _intro(UserRole role) {
    return switch (role) {
      UserRole.customer => 'Personal details for your bookings and orders.',
      UserRole.provider => 'Professional details shown with your services.',
      UserRole.supplier => 'Business details shown with your products.',
      UserRole.admin => 'This account is not managed in the mobile app.',
    };
  }
}

class _RoleLabel extends StatelessWidget {
  const _RoleLabel({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x14163B60),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.badge_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Role: ${role.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
