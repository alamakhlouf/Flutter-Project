import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
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
    _service = widget.servicesService ??
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
        _error = 'Unable to load services. Check your connection and try again.';
      });
    }
  }

  void _onCategorySelected(String cat) {
    if (_category == cat) return;
    setState(() => _category = cat);
    _loadCatalog();
  }

  void _openFilterSheet() {
    ServiceFilterSheet.show(
      context: context,
      selectedCategory: _category,
      maxPrice: _maxPrice,
      location: _location,
      onApply: ({category, maxPrice, location}) {
        setState(() {
          _category = category ?? 'All';
          _maxPrice = maxPrice;
          _location = location;
        });
        _loadCatalog();
      },
    );
  }

  bool get _hasActiveFilters =>
      _category != 'All' || _maxPrice != null || (_location != null && _location!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['All', ...ServiceCategory.all];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Catalog'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                key: ServicesKeys.catalogFilterButton,
                icon: const Icon(Icons.tune_outlined),
                tooltip: 'Filter services',
                onPressed: _openFilterSheet,
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
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
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
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
      return const Center(
        child: CircularProgressIndicator(),
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
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
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
            Navigator.of(context).pushNamed(
              AppRoutes.serviceDetails,
              arguments: service,
            );
          },
        );
      },
    );
  }
}
