import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serviceApi = widget.servicesService ??
        ServicesService(api: AuthScope.of(context).api);

    final args = ModalRoute.of(context)?.settings.arguments;
    if (_service == null && args is ServiceModel) {
      _service = args;
    }

    final targetId = widget.serviceId ??
        (args is String ? args : null) ??
        _service?.id;

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
      appBar: AppBar(
        title: Text(_service?.title ?? 'Service Details'),
      ),
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
            padding: EdgeInsets.zero,
            children: [
              _buildHeaderImage(s),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            s.title,
                            style: theme.textTheme.headlineLarge,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ServiceStatusBadge(isActive: s.isActive),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neutral,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            s.category,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          s.formattedPrice,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (s.location != null && s.location!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              s.location!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 16),
                    Text(
                      'Provider Information',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildProviderCard(theme, s),
                    const SizedBox(height: 24),
                    Text(
                      'Description',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildBottomBookingBar(theme, s, isOwner, canBook, user),
      ],
    );
  }

  Widget _buildHeaderImage(ServiceModel s) {
    final validUrl = s.imageUrl != null &&
        s.imageUrl!.isNotEmpty &&
        (s.imageUrl!.startsWith('http://') || s.imageUrl!.startsWith('https://'));

    return Container(
      height: 220,
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.08),
      child: validUrl
          ? Image.network(
              s.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(s.category),
            )
          : _imagePlaceholder(s.category),
    );
  }

  Widget _imagePlaceholder(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handyman_outlined,
            size: 56,
            color: AppColors.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(ThemeData theme, ServiceModel s) {
    final name = s.providerName ?? 'Service Provider';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
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
                    style: theme.textTheme.titleLarge,
                  ),
                  if (s.providerEmail != null && s.providerEmail!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.providerEmail!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (s.providerPhone != null && s.providerPhone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.providerPhone!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBookingBar(
    ThemeData theme,
    ServiceModel s,
    bool isOwner,
    bool canBook,
    AuthUser user,
  ) {
    String buttonText = 'Book Service';
    String? hintText;

    if (!s.isActive) {
      buttonText = 'Service Currently Inactive';
      hintText = 'This service is currently unavailable for booking.';
    } else if (isOwner) {
      buttonText = 'Manage Service';
      hintText = 'You own this service.';
    } else if (user.role != UserRole.customer) {
      buttonText = 'Customer Booking Only';
      hintText = 'Only registered customers can book services.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hintText != null) ...[
              Text(
                hintText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              key: ServicesKeys.detailsBookButton,
              onPressed: canBook
                  ? () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.createBooking,
                        arguments: s,
                      );
                    }
                  : (isOwner
                      ? () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.editService,
                            arguments: s,
                          );
                        }
                      : null),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
