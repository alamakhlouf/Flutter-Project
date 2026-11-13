import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/inventory_product_model.dart';
import '../services/inventory_product_service.dart';
import '../widgets/inventory_product_card.dart';
import '../../../app/app_routes.dart';
import '../../auth/models/auth_user.dart';

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
    var enteredQuantity = '1';
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy ${product.name}'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          onChanged: (value) => enteredQuantity = value,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(enteredQuantity.trim());
              if (parsed == null || parsed < 1) return;
              Navigator.pop(context, parsed);
            },
            child: const Text('Place order'),
          ),
        ],
      ),
    );
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

  Future<void> _openDetails(InventoryProduct product) async {
    final ordered = await Navigator.of(context)
        .pushNamed(AppRoutes.inventoryDetails, arguments: product);
    if (ordered == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully.')),
      );
      await _loadProducts(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AuthScope.of(context).user.role;
    final canManageInventory =
        role == UserRole.provider || role == UserRole.supplier;
    return Scaffold(
      appBar: AppBar(title: const Text('Available Inventory')),
      floatingActionButton: canManageInventory
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('My inventory'),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.inventoryList),
            )
          : null,
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
              child: _buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  InventoryProductService get _service => _productService!;

  Widget _buildBody(BuildContext context) {
    final userRole = AuthScope.of(context).user.role;
    final isAdmin = userRole == UserRole.admin;

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
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InventoryProductCard(
            product: product,
            actions: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _openDetails(product),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('View details'),
                ),
                if (!isAdmin)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => _buy(product),
                    child: const Text('Buy'),
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
