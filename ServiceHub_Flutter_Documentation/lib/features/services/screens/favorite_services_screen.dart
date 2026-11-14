import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/service_model.dart';
import '../services/services_service.dart';
import '../widgets/services_widgets.dart';

class FavoriteServicesScreen extends StatefulWidget {
  const FavoriteServicesScreen({super.key, this.servicesService});

  final ServicesService? servicesService;

  @override
  State<FavoriteServicesScreen> createState() => _FavoriteServicesScreenState();
}

class _FavoriteServicesScreenState extends State<FavoriteServicesScreen> {
  ServicesService? _servicesService;
  List<ServiceModel> _services = <ServiceModel>[];
  var _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _servicesService ??=
        widget.servicesService ??
        ServicesService(api: AuthScope.of(context).api);
    if (_loading && _services.isEmpty && _error == null) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await _service.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _services = items;
        _loading = false;
        _error = null;
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
        _error = 'Unable to load favorite services.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite(ServiceModel service) async {
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index == -1) return;

    setState(() {
      _services.removeAt(index);
    });

    try {
      await _service.unfavoriteService(service.id);
    } on ApiException catch (e) {
      await _loadFavorites(showLoading: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openDetails(ServiceModel service) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.serviceDetails,
      arguments: service,
    );
    await _loadFavorites(showLoading: false);
  }

  ServicesService get _service => _servicesService!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Services')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _loadFavorites(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadFavorites(showLoading: false),
              child: _services.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 56,
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No favorite services yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Services you favorite will appear here.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _services.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return ServiceCard(
                          service: service,
                          onTap: () => _openDetails(service),
                          onToggleFavorite: () => _toggleFavorite(service),
                        );
                      },
                    ),
            ),
    );
  }
}
