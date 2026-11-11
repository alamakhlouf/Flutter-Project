import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../models/inventory_product_model.dart';
import '../services/inventory_product_service.dart';
import '../../../app/app_routes.dart';

class InventoryCatalogScreen extends StatefulWidget {
  const InventoryCatalogScreen({super.key, this.productService});

  final InventoryProductService? productService;

  @override
  State<InventoryCatalogScreen> createState() => _InventoryCatalogScreenState();
}

class _InventoryCatalogScreenState extends State<InventoryCatalogScreen> {
  InventoryProductService? _productService;
  final _searchController = TextEditingController();
  var _loading = true;
  String? _error;
  List<InventoryProduct> _products = <InventoryProduct>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productService ??=
        widget.productService ??
        InventoryProductService(api: AuthScope.of(context).api);
    if (_loading && _products.isEmpty && _error == null) {
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final products = await _service.fetchAvailable(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _products = products
            .where(
              (product) =>
                  product.quantityAvailable == null ||
                  product.quantityAvailable! > 0,
            )
            .toList();
        _loading = false;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load available inventory. Try again.';
      });
    }
  }

  Future<void> _buy(InventoryProduct product) async {
    final controller = TextEditingController(text: '1');
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy ${product.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 1) return;
              Navigator.pop(context, parsed);
            },
            child: const Text('Place order'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (quantity == null || !mounted) return;

    try {
      await _service.buyProduct(product.id, quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully.')),
      );
      await _loadProducts(showLoading: false);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canBuy = AuthScope.of(context).user.role == UserRole.customer;
    return Scaffold(
      appBar: AppBar(title: const Text('Available Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadProducts(),
              decoration: InputDecoration(
                hintText: 'Search inventory',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _loadProducts();
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadProducts(showLoading: false),
              child: _buildBody(context, canBuy),
            ),
          ),
        ],
      ),
    );
  }

  InventoryProductService get _service => _productService!;

  Widget _buildBody(BuildContext context, bool canBuy) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _MessageState(
        message: _error!,
        action: TextButton(
          onPressed: _loadProducts,
          child: const Text('Try again'),
        ),
      );
    }
    if (_products.isEmpty) {
      return const _MessageState(message: 'No available inventory found.');
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text('${product.category} · ${product.supplierName}'),
                if (product.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(product.description!),
                ],
                const SizedBox(height: 8),
                Text(
                  '${product.price.toStringAsFixed(2)} DZD'
                  '${product.quantityAvailable == null ? '' : ' · ${product.quantityAvailable} available'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.inventoryDetails,
                        arguments: product,
                      ),
                      child: const Text('Details'),
                    ),
                    if (canBuy) ...[
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _buy(product),
                        child: const Text('Buy'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(child: Text(message, textAlign: TextAlign.center)),
        if (action != null) Center(child: action),
      ],
    );
  }
}
