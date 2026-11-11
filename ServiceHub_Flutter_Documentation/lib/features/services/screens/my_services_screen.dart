import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/service_model.dart';
import '../services/services_service.dart';
import '../services_keys.dart';
import '../widgets/services_widgets.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key, this.servicesService});

  final ServicesService? servicesService;

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  late final ServicesService _serviceApi;

  var _loading = true;
  String? _error;
  List<ServiceModel> _services = <ServiceModel>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serviceApi = widget.servicesService ??
        ServicesService(api: AuthScope.of(context).api);
    if (_loading && _services.isEmpty && _error == null) {
      _loadMyServices();
    }
  }

  Future<void> _loadMyServices({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await _serviceApi.fetchMyServices();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _services = items;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load your services. Try again.';
      });
    }
  }

  Future<void> _toggleActive(ServiceModel service, bool newValue) async {
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index == -1) return;

    // Optimistic UI update
    final updated = service.copyWith(isActive: newValue);
    setState(() {
      _services[index] = updated;
    });

    try {
      final serverResult = await _serviceApi.toggleServiceActive(
        id: service.id,
        isActive: newValue,
      );
      if (!mounted) return;
      setState(() {
        _services[index] = serverResult;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // Revert optimistic update
      setState(() {
        _services[index] = service;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteService(ServiceModel service) async {
    final confirmed = await DeleteServiceDialog.show(context, service.title);
    if (!confirmed || !mounted) return;

    try {
      await _serviceApi.deleteService(service.id);
      if (!mounted) return;
      setState(() {
        _services.removeWhere((s) => s.id == service.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service "${service.title}" deleted.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(context).pushNamed(AppRoutes.createService);
    if (created == true && mounted) {
      _loadMyServices();
    }
  }

  Future<void> _openEditForm(ServiceModel service) async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.editService,
      arguments: service,
    );
    if (updated == true && mounted) {
      _loadMyServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(
            key: ServicesKeys.createServiceButton,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create new service',
            onPressed: _openCreateForm,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: ServicesKeys.createServiceButton,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Service'),
        onPressed: _openCreateForm,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMyServices(showLoading: false),
        color: AppColors.primary,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
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
              Text('Unable to Load Services', style: theme.textTheme.titleLarge),
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
                key: ServicesKeys.myServicesRetryButton,
                onPressed: _loadMyServices,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.storefront_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Services Created Yet',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start offering services to local customers by creating your first listing.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: _openCreateForm,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Service'),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return ServiceCard(
          service: service,
          isProviderView: true,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.serviceDetails,
              arguments: service,
            );
          },
          onToggleActive: (val) => _toggleActive(service, val),
          onEdit: () => _openEditForm(service),
          onDelete: () => _deleteService(service),
        );
      },
    );
  }
}
