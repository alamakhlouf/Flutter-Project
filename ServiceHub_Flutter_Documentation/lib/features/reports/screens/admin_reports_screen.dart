import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key, this.reportService});

  final ReportService? reportService;

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  ReportService? _service;
  List<ReportModel> _reports = const [];
  String? _error;
  bool _loading = true;
  String _filterStatus = 'ALL';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service ??=
        widget.reportService ?? ReportService(api: AuthScope.of(context).api);
    if (_loading && _error == null && _reports.isEmpty) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports =
          await _service!.fetchAdminReports(status: _filterStatus);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load admin reports. Try again.';
        _loading = false;
      });
    }
  }

  Future<void> _blockUser(ReportModel report) async {
    final displayName = report.targetTitle?.isNotEmpty == true
        ? report.targetTitle!
        : report.targetId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Block Reported User?'),
        content: Text(
          'Are you sure you want to block "$displayName"? They will lose access to ServiceHub.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block User'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service!.blockUser(report.targetId);
      await _service!.updateReportStatus(report.id, 'RESOLVED');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User account blocked and report resolved.'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not block user: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteService(ReportModel report) async {
    final displayName = report.targetTitle?.isNotEmpty == true
        ? report.targetTitle!
        : report.targetId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Reported Service?'),
        content: Text(
          'Are you sure you want to delete service "$displayName"? This service listing will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Service'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service!.deleteAdminService(report.targetId);
      await _service!.updateReportStatus(report.id, 'RESOLVED');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service deleted and report resolved.'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete service: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateStatus(ReportModel report, String newStatus) async {
    try {
      await _service!.updateReportStatus(report.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report updated to $newStatus.'),
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update report: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text(
          'Admin Moderation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                for (final status in ['ALL', 'PENDING', 'RESOLVED', 'DISMISSED'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: _filterStatus == status,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: _filterStatus == status
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: _filterStatus == status
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _filterStatus = status);
                          _load();
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredReports = _reports.where((report) {
      if (_filterStatus == 'ALL') return true;
      final statusUpper = report.status.trim().toUpperCase();
      final filterUpper = _filterStatus.trim().toUpperCase();
      if (filterUpper == 'PENDING' || filterUpper == 'OPEN') {
        return statusUpper == 'PENDING' ||
            statusUpper == 'OPEN' ||
            statusUpper == 'UNDER_REVIEW';
      }
      return statusUpper == filterUpper;
    }).toList();

    if (filteredReports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Reports Found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'There are currently no user reports requiring moderation under this filter.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: filteredReports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final report = filteredReports[index];
          return _AdminReportCard(
            report: report,
            onBlockUser: () => _blockUser(report),
            onDeleteService: () => _deleteService(report),
            onResolve: () => _updateStatus(report, 'RESOLVED'),
            onDismiss: () => _updateStatus(report, 'DISMISSED'),
          );
        },
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  const _AdminReportCard({
    required this.report,
    required this.onBlockUser,
    required this.onDeleteService,
    required this.onResolve,
    required this.onDismiss,
  });

  final ReportModel report;
  final VoidCallback onBlockUser;
  final VoidCallback onDeleteService;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetUpper = report.targetType.toUpperCase();
    final isUserTarget = targetUpper == 'USER' ||
        targetUpper == 'PROFILE' ||
        targetUpper == 'PROVIDER' ||
        targetUpper == 'SUPPLIER' ||
        targetUpper == 'CUSTOMER' ||
        targetUpper.contains('USER') ||
        targetUpper.contains('PROVIDER') ||
        targetUpper.contains('PROFILE');

    final isServiceTarget = targetUpper == 'SERVICE' ||
        targetUpper == 'SERVICES' ||
        targetUpper.contains('SERVICE');

    final statusColor = switch (report.status.toUpperCase()) {
      'RESOLVED' => AppColors.success,
      'DISMISSED' => AppColors.textSecondary,
      _ => AppColors.warning,
    };

    final targetIcon = isServiceTarget
        ? Icons.home_repair_service_rounded
        : isUserTarget
            ? Icons.person_rounded
            : Icons.label_important_outline_rounded;

    final defaultTargetTitle = isServiceTarget
        ? 'Reported Service'
        : isUserTarget
            ? 'Reported User Profile'
            : 'Reported ${report.targetType}';

    final displayTitle = report.targetTitle?.isNotEmpty == true
        ? report.targetTitle!
        : defaultTargetTitle;

    final date = report.createdAt?.toLocal();
    final dateLabel = date == null
        ? null
        : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/${date.year}';

    final isPending = report.status.toUpperCase() == 'PENDING' ||
        report.status.toUpperCase() == 'OPEN' ||
        report.status.toUpperCase() == 'UNDER_REVIEW';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  report.targetType.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Target Name / Service Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  targetIcon,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target ID: ${report.targetId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'Monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Reason & Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neutral,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.report_problem_outlined,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${report.reason}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (report.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    report.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (report.reporterName?.isNotEmpty == true || dateLabel != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (report.reporterName?.isNotEmpty == true)
                  Text(
                    'Reported by ${report.reporterName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (dateLabel != null)
                  Text(
                    'Date: $dateLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          // Moderation Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isUserTarget && isPending) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onBlockUser,
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: Text(
                    report.targetTitle?.isNotEmpty == true
                        ? 'Block Profile (${report.targetTitle})'
                        : 'Block Reported Profile',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (isServiceTarget && isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.serviceDetails,
                          arguments: report.targetId,
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('View Service'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onDeleteService,
                        icon: const Icon(Icons.delete_forever_rounded, size: 18),
                        label: const Text('Delete Service'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  if (report.status.toUpperCase() != 'RESOLVED')
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onResolve,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark Resolved'),
                      ),
                    ),
                  if (report.status.toUpperCase() != 'RESOLVED')
                    const SizedBox(width: 8),
                  if (report.status.toUpperCase() != 'DISMISSED')
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Dismiss Report'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
