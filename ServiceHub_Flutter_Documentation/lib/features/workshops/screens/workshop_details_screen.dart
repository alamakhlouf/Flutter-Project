import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../../reports/models/report_target.dart';
import '../models/workshop_model.dart';
import '../services/workshop_service.dart';
import '../utils/workshop_date_format.dart';
import '../widgets/workshop_image.dart';

class WorkshopDetailsScreen extends StatefulWidget {
  const WorkshopDetailsScreen({super.key, required this.workshop});

  final WorkshopModel workshop;

  @override
  State<WorkshopDetailsScreen> createState() => _WorkshopDetailsScreenState();
}

class _WorkshopDetailsScreenState extends State<WorkshopDetailsScreen> {
  late final WorkshopService _service;
  late WorkshopModel _workshop;
  bool _busy = false;
  bool _serviceInitialized = false;
  bool _checkingRegistration = true;
  bool _registrationCheckFailed = false;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _workshop = widget.workshop;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_serviceInitialized) return;
    _serviceInitialized = true;
    _service = WorkshopService(api: AuthScope.of(context).api);

    final isAdmin = AuthScope.of(context).user.role == UserRole.admin;
    if (isAdmin) {
      setState(() => _checkingRegistration = false);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRegistrationStatus();
    });
  }

  Future<void> _loadRegistrationStatus() async {
    setState(() {
      _checkingRegistration = true;
      _registrationCheckFailed = false;
    });
    try {
      final registrations = await _service.fetchMyRegistrations();
      if (!mounted) return;
      setState(() {
        _isRegistered = registrations.any(
          (registration) =>
              registration.workshopId == _workshop.id && registration.isActive,
        );
        _checkingRegistration = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _checkingRegistration = false;
        _registrationCheckFailed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check workshop registration: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _register() async {
    setState(() => _busy = true);
    try {
      await _service.register(_workshop.id);
      if (mounted) setState(() => _isRegistered = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration confirmed.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthScope.of(context).user;
    final isAdmin = user.role == UserRole.admin;
    final workshop = _workshop;

    final canRegister =
        !isAdmin &&
        workshop.status == WorkshopStatus.published &&
        !workshop.registrationClosed;

    final registrationLabel = isAdmin
        ? 'Admin View Mode'
        : _isRegistered
        ? 'Registered'
        : _checkingRegistration
        ? 'Checking registration...'
        : _registrationCheckFailed
        ? 'Retry registration check'
        : workshop.isFull
        ? 'Workshop full'
        : 'Register';

    return Scaffold(
      appBar: AppBar(title: const Text('Workshop details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            elevation: 1,
            shadowColor: AppColors.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WorkshopImage(imageUrl: workshop.coverImageUrl, height: 190),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workshop.category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          _WorkshopStatusBadge(
                            label: workshop.isFull
                                ? 'Full'
                                : workshop.status.label,
                            color: workshop.isFull
                                ? AppColors.warning
                                : workshop.status.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        workshop.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WorkshopDetailRow(
                        icon: Icons.person_outline,
                        title: 'Organizer',
                        value: workshop.organizerName,
                      ),
                      const SizedBox(height: 10),
                      _WorkshopDetailRow(
                        icon: Icons.schedule_outlined,
                        title: 'Starts',
                        value: formatWorkshopDateTime(workshop.startDateTime),
                      ),
                      const SizedBox(height: 10),
                      _WorkshopDetailRow(
                        icon: Icons.event_available_outlined,
                        title: 'Ends',
                        value: formatWorkshopDateTime(workshop.endDateTime),
                      ),
                      const SizedBox(height: 10),
                      _WorkshopDetailRow(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        value: workshop.location,
                      ),
                      const SizedBox(height: 10),
                      _WorkshopDetailRow(
                        icon: Icons.groups_outlined,
                        title: 'Capacity',
                        value:
                            '${workshop.participantCount}/${workshop.capacity} registered',
                      ),
                      const SizedBox(height: 10),
                      _WorkshopDetailRow(
                        icon: Icons.timer_outlined,
                        title: 'Registration closes',
                        value: formatWorkshopDateTime(
                          workshop.registrationDeadline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isAdmin || _isRegistered || _busy
                              ? null
                              : _registrationCheckFailed
                              ? _loadRegistrationStatus
                              : canRegister && !_checkingRegistration
                              ? _register
                              : null,
                          icon: Icon(
                            isAdmin
                                ? Icons.visibility_outlined
                                : _isRegistered
                                ? Icons.check_circle_outline
                                : Icons.how_to_reg,
                          ),
                          label: Text(registrationLabel),
                        ),
                      ),
                      if (!isAdmin) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pushNamed(
                                AppRoutes.createReport,
                                arguments: ReportTarget(
                                  type: 'WORKSHOP',
                                  id: workshop.id,
                                  title: 'Report workshop',
                                  subtitle: workshop.title,
                                ),
                              ),
                              icon: const Icon(Icons.flag_outlined),
                              label: const Text('Report workshop'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pushNamed(
                                AppRoutes.createReport,
                                arguments: ReportTarget(
                                  type: 'PROVIDER',
                                  id: workshop.organizerId,
                                  title: 'Report provider',
                                  subtitle: workshop.organizerName,
                                ),
                              ),
                              icon: const Icon(Icons.person_outline),
                              label: const Text('Report provider'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About this workshop',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workshop.description.isEmpty
                        ? 'No description provided.'
                        : workshop.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopStatusBadge extends StatelessWidget {
  const _WorkshopStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

class _WorkshopDetailRow extends StatelessWidget {
  const _WorkshopDetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    ],
  );
}
