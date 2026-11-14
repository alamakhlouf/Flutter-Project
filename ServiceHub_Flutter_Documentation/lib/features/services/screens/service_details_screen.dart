import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/image_renderer.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../../reports/models/report_target.dart';
import '../../reviews/services/review_service.dart';
import '../../reviews/widgets/reviews_section.dart';
import '../models/service_model.dart';
import '../services/services_service.dart';
import '../services_keys.dart';
import '../widgets/services_widgets.dart';

class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({
    super.key,
    this.service,
    this.serviceId,
    this.servicesService,
  });

  final ServiceModel? service;
  final String? serviceId;
  final ServicesService? servicesService;

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  late final ServicesService _serviceApi;
  ServiceModel? _service;
  var _loading = false;
  var _serviceInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serviceInitialized) {
      _serviceInitialized = true;
      _serviceApi =
          widget.servicesService ??
          ServicesService(api: AuthScope.of(context).api);
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (_service == null && args is ServiceModel) {
      _service = args;
    }

    final targetId =
        widget.serviceId ?? (args is String ? args : null) ?? _service?.id;

    if (_service == null && targetId != null && !_loading && _error == null) {
      _fetchDetails(targetId);
    }
  }

  Future<void> _fetchDetails(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _serviceApi.getServiceById(id);
      if (!mounted) return;
      setState(() {
        _service = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load service details.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthScope.of(context).user;

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(title: const Text('Service details')),
      body: _buildContent(theme, user),
    );
  }

  Widget _buildContent(ThemeData theme, AuthUser user) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error Loading Service', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: ServicesKeys.detailsRetryButton,
                onPressed: () {
                  final id = widget.serviceId ?? _service?.id;
                  if (id != null) _fetchDetails(id);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final s = _service;
    if (s == null) {
      return const Center(child: Text('Service not found.'));
    }

    final isOwner = user.id == s.providerId;
    final canBook = s.isActive && !isOwner && user.role == UserRole.customer;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _buildServiceSummary(
                theme,
                s,
                isOwner: isOwner,
                canBook: canBook,
                user: user,
              ),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                color: AppColors.surface,
                elevation: 1,
                shadowColor: AppColors.primary.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildProviderCard(theme, s),
              const SizedBox(height: 16),
              ReviewsSection(
                reviewService: ReviewService(api: AuthScope.of(context).api),
                serviceId: s.id,
              ),
              if (user.role != UserRole.admin) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.createReport,
                        arguments: ReportTarget(
                          type: 'SERVICE',
                          id: s.id,
                          title: 'Report service',
                          subtitle: s.title,
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Report service'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.createReport,
                        arguments: ReportTarget(
                          type: 'PROVIDER',
                          id: s.providerId,
                          title: 'Report provider',
                          subtitle: s.providerName ?? 'Service provider',
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
    );
  }

  Widget _buildServiceSummary(
    ThemeData theme,
    ServiceModel service, {
    required bool isOwner,
    required bool canBook,
    required AuthUser user,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildHeaderImage(service),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.category.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ServiceStatusBadge(
                      isActive: service.isActive,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  service.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (service.providerName?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'by ${service.providerName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (service.location?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        service.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.price != null && service.price! > 0
                                ? 'Starting at'
                                : 'Pricing',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service.formattedPrice,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _buildBookingAction(
                        theme,
                        service,
                        isOwner,
                        canBook,
                        user,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(ServiceModel s) {
    final validUrl =
        s.imageUrl != null &&
        s.imageUrl!.isNotEmpty &&
        (s.imageUrl!.startsWith('http://') ||
            s.imageUrl!.startsWith('https://'));

    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.surface,
      child: validUrl
          ? Image.network(
              s.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _imagePlaceholder(s.category, s.imageUrl!),
            )
          : _imagePlaceholder(s.category, s.imageUrl!),
    );
  }

  Widget _imagePlaceholder(String category, String imageUrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ServiceHeaderImage(imageUrl: imageUrl, category: category),
        ],
      ),
    );
  }

  Widget _buildProviderCard(ThemeData theme, ServiceModel s) {
    final name = s.providerName ?? 'Service Provider';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Provider Information',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.neutral,
                  foregroundColor: AppColors.primary,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (s.providerEmail != null &&
                          s.providerEmail!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.providerEmail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (s.providerPhone != null &&
                          s.providerPhone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.providerPhone!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingAction(
    ThemeData theme,
    ServiceModel s,
    bool isOwner,
    bool canBook,
    AuthUser user,
  ) {
    String buttonText = 'Book Service';
    String? hintText;

    if (user.role == UserRole.admin) {
      buttonText = 'Admin View Mode';
      hintText = 'Admin account — view only.';
    } else if (!s.isActive) {
      buttonText = 'Service Currently Inactive';
      hintText = 'This service is currently unavailable for booking.';
    } else if (isOwner) {
      buttonText = 'Manage Service';
      hintText = 'You own this service.';
    } else if (user.role != UserRole.customer) {
      buttonText = 'Customer Booking Only';
      hintText = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          key: ServicesKeys.detailsBookButton,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          onPressed: user.role == UserRole.admin
              ? null
              : (canBook
                  ? () {
                      Navigator.of(context)
                          .pushNamed(AppRoutes.createBooking, arguments: s);
                    }
                  : (isOwner
                      ? () {
                          Navigator.of(context)
                              .pushNamed(AppRoutes.editService, arguments: s);
                        }
                      : null)),
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hintText != null) ...[
          const SizedBox(height: 5),
          SizedBox(
            width: 140,
            child: Text(
              hintText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ],
    );
  }
}


class _ServiceHeaderImage extends StatelessWidget {
  const _ServiceHeaderImage({required this.imageUrl, required this.category});

  final String? imageUrl;
  final String category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageRenderer(
            imageUrl: imageUrl,
            placeholder: _placeholder(category),
            fit: BoxFit.cover,
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(String category) {
    IconData icon;
    switch (category) {
      case ServiceCategory.cleaning:
        icon = Icons.cleaning_services_outlined;
        break;
      case ServiceCategory.plumbing:
        icon = Icons.plumbing_outlined;
        break;
      case ServiceCategory.electrical:
        icon = Icons.electrical_services_outlined;
        break;
      case ServiceCategory.tutoring:
        icon = Icons.school_outlined;
        break;
      case ServiceCategory.beauty:
        icon = Icons.spa_outlined;
        break;
      case ServiceCategory.fitness:
        icon = Icons.fitness_center_outlined;
        break;
      case ServiceCategory.event:
        icon = Icons.event_outlined;
        break;
      case ServiceCategory.homeCare:
        icon = Icons.home_repair_service_outlined;
        break;
      default:
        icon = Icons.miscellaneous_services_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: AppColors.primary.withValues(alpha: 0.38),
          ),
        ],
      ),
    );
  }
}

