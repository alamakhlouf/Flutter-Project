import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../models/service_model.dart';
import '../services/services_service.dart';
import '../services_keys.dart';
import '../widgets/services_widgets.dart';

class ServicesCatalogScreen extends StatefulWidget {
  const ServicesCatalogScreen({super.key, this.servicesService});

  final ServicesService? servicesService;

  @override
  State<ServicesCatalogScreen> createState() => _ServicesCatalogScreenState();
}

class _ServicesCatalogScreenState extends State<ServicesCatalogScreen> {
  late final ServicesService _service;
  late final TextEditingController _searchController;

  var _loading = true;
  var _initialized = false;
  String? _error;
  List<ServiceModel> _services = <ServiceModel>[];

  String _category = 'All';
  double? _maxPrice;
  String? _location;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _service =
        widget.servicesService ??
        ServicesService(api: AuthScope.of(context).api);
    if (_loading && _services.isEmpty && _error == null) {
      _loadCatalog();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(ServiceModel service) async {
    final index = _services.indexWhere((s) => s.id == service.id);
    if (index == -1) return;

    final newFavorite = !service.favorite;
    setState(() {
      _services[index] = service.copyWith(favorite: newFavorite);
    });

    try {
      if (service.favorite) {
        await _service.unfavoriteService(service.id);
      } else {
        await _service.favoriteService(service.id);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _services[index] = service;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _loadCatalog({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await _service.fetchCatalog(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        category: _category == 'All' ? null : _category,
        maxPrice: _maxPrice,
        location: _location,
      );
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
        _error =
            'Unable to load services. Check your connection and try again.';
      });
    }
  }

  void _onCategorySelected(String cat) {
    if (_category == cat) return;
    setState(() => _category = cat);
    _loadCatalog();
  }

  bool get _hasActiveFilters =>
      _category != 'All' ||
      _maxPrice != null ||
      (_location != null && _location!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['All', ...ServiceCategory.all];
    final isProvider = AuthScope.of(context).user.role == UserRole.provider;

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        title: const Text('Services Catalog'),
        actions: [
          const NotificationBell(),
          if (isProvider)
            IconButton(
              key: ServicesKeys.openMyServices,
              tooltip: 'My Services',
              icon: const Icon(Icons.manage_accounts_outlined),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.myServices),
            ),
          IconButton(
            key: ServicesKeys.catalogFavoritesButton,
            icon: const Icon(Icons.favorite_border_rounded),
            tooltip: 'Favorite services',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.favoriteServices),
          ),
        ],
      ),
      floatingActionButton: isProvider
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Create service'),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.createService),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: ServicesKeys.catalogSearchInput,
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadCatalog(),
              decoration: InputDecoration(
                hintText: 'Search services by title or description...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _loadCatalog();
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return CategoryChip(
                  label: cat,
                  isSelected: _category == cat,
                  onSelected: () => _onCategorySelected(cat),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadCatalog(showLoading: false),
              color: AppColors.primary,
              child: _buildBody(theme),
            ),
          ),
        ],
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
              Text(
                'Failed to load services',
                style: theme.textTheme.titleLarge,
              ),
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
                key: ServicesKeys.catalogRetryButton,
                onPressed: _loadCatalog,
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
          const SizedBox(height: 40),
          const Icon(
            Icons.search_off_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No services found',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query or filters to discover available services.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_hasActiveFilters || _searchController.text.isNotEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _category = 'All';
                    _maxPrice = null;
                    _location = null;
                  });
                  _loadCatalog();
                },
                child: const Text('Clear Search & Filters'),
              ),
            ),
          ],
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return ServiceCard(
          service: service,
          onTap: () {
            Navigator.of(context)
                .pushNamed(AppRoutes.serviceDetails, arguments: service);
          },
          onToggleFavorite: () => _toggleFavorite(service),
        );
      },
    );
  }
}
