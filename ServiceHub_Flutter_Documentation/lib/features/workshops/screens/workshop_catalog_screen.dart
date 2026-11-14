import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../models/workshop_model.dart';
import '../services/workshop_service.dart';
import '../utils/workshop_date_format.dart';
import '../widgets/workshop_image.dart';
import 'workshop_details_screen.dart';

class WorkshopCatalogScreen extends StatefulWidget {
  const WorkshopCatalogScreen({super.key});

  @override
  State<WorkshopCatalogScreen> createState() => _WorkshopCatalogScreenState();
}

class _WorkshopCatalogScreenState extends State<WorkshopCatalogScreen> {
  late WorkshopService _service;
  final _search = TextEditingController();
  List<WorkshopModel> _items = [];
  String? _error;
  bool _loading = true;
  bool _availableOnly = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _service = WorkshopService(api: AuthScope.of(context).api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchWorkshops(
        search: _search.text,
        availability: _availableOnly,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load workshops: $error';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthScope.of(context).user.role;
    final isProvider = role == UserRole.provider;
    final canRegister = role == UserRole.customer || isProvider;
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text(
          'Workshops',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          const NotificationBell(),
          if (isProvider)
            IconButton(
              tooltip: 'My Workshops',
              icon: const Icon(Icons.event_note_outlined),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.myWorkshops),
            ),
          if (canRegister)
            IconButton(
              tooltip: 'My Registrations',
              icon: const Icon(Icons.confirmation_number_outlined),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed(AppRoutes.myWorkshopRegistrations),
            ),
        ],
      ),
      floatingActionButton: isProvider
          ? FloatingActionButton.extended(
              elevation: 3,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create Workshop',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.createWorkshop),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search workshops by title or location...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Show available spots only',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.3),
              value: _availableOnly,
              onChanged: (value) {
                setState(() => _availableOnly = value);
                _load();
              },
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
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
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Published Workshops Found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Check back later or adjust your search filters.',
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final workshop = _items[index];
          return _WorkshopCard(
            workshop: workshop,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WorkshopDetailsScreen(workshop: workshop),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}

class _WorkshopCard extends StatelessWidget {
  const _WorkshopCard({required this.workshop, required this.onTap});

  final WorkshopModel workshop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = workshop.isFull
        ? AppColors.warning
        : workshop.status.color;

    final progressRatio = workshop.capacity > 0
        ? (workshop.participantCount / workshop.capacity).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  WorkshopImage(
                    imageUrl: workshop.coverImageUrl,
                    height: 165,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        workshop.category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _WorkshopStatusBadge(
                      label: workshop.isFull ? 'Full' : workshop.status.label,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MetadataRow(
                      icon: Icons.person_outline_rounded,
                      text: 'Hosted by ${workshop.organizerName}',
                    ),
                    const SizedBox(height: 6),
                    _MetadataRow(
                      icon: Icons.schedule_rounded,
                      text: formatWorkshopDateTime(workshop.startDateTime),
                    ),
                    const SizedBox(height: 6),
                    _MetadataRow(
                      icon: Icons.location_on_outlined,
                      text: workshop.location,
                    ),
                    const SizedBox(height: 14),
                    // Participant capacity progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Participants',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${workshop.participantCount} / ${workshop.capacity} spots filled',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: workshop.isFull
                                    ? AppColors.warning
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            minHeight: 6,
                            backgroundColor: AppColors.neutral,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              workshop.isFull
                                  ? AppColors.warning
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'View Workshop Details',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      );
}
