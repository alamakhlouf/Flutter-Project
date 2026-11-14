import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/inventory_product_model.dart';
import '../services/inventory_product_service.dart';
import '../widgets/inventory_product_card.dart';

class FavoriteProductsScreen extends StatefulWidget {
  const FavoriteProductsScreen({super.key, this.productService});

  final InventoryProductService? productService;

  @override
  State<FavoriteProductsScreen> createState() => _FavoriteProductsScreenState();
}

class _FavoriteProductsScreenState extends State<FavoriteProductsScreen> {
  InventoryProductService? _productService;
  List<InventoryProduct> _products = <InventoryProduct>[];
  var _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productService ??=
        widget.productService ??
        InventoryProductService(api: AuthScope.of(context).api);
    if (_loading && _products.isEmpty && _error == null) {
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
        _products = items;
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
        _error = 'Unable to load favorite products.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite(InventoryProduct product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) return;

    setState(() {
      _products.removeAt(index);
    });

    try {
      await _service.unfavoriteProduct(product.id);
    } on ApiException catch (e) {
      await _loadFavorites(showLoading: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openDetails(InventoryProduct product) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.inventoryDetails,
      arguments: product,
    );
    await _loadFavorites(showLoading: false);
  }

  InventoryProductService get _service => _productService!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Products')),
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
              child: _products.isEmpty
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
                                'No favorite products yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Products you favorite will appear here.',
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
                      itemCount: _products.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return InventoryProductCard(
                          product: product,
                          showOwnerStockStatus: true,
                          actions: IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: AppColors.error,
                            ),
                            onPressed: () => _toggleFavorite(product),
                            tooltip: 'Remove from favorites',
                          ),
                          onTap: () => _openDetails(product),
                          onToggleFavorite: () => _toggleFavorite(product),
                        );
                      },
                    ),
            ),
    );
  }
}
