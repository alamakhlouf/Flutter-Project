import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/inventory_product_model.dart';
import '../services/inventory_product_service.dart';
import '../widgets/inventory_product_card.dart';
import 'supplier_inventory_form_screen.dart';

class SupplierInventoryScreen extends StatefulWidget {
  const SupplierInventoryScreen({super.key, this.productService});

  final InventoryProductService? productService;

  @override
  State<SupplierInventoryScreen> createState() =>
      _SupplierInventoryScreenState();
}

class _SupplierInventoryScreenState extends State<SupplierInventoryScreen> {
  InventoryProductService? _productService;
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

  Future<void> _loadProducts({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final products = await _service.fetchMyProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
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
        _error = 'Unable to load your inventory. Try again.';
      });
    }
  }

  Future<void> _openForm([InventoryProduct? product]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SupplierInventoryFormScreen(
          productService: _service,
          product: product,
        ),
      ),
    );
    if (saved == true && mounted) _loadProducts();
  }

  Future<void> _setAvailable(InventoryProduct product, bool available) async {
    try {
      final updated = await _service.setAvailability(product.id, available);
      if (!mounted) return;
      setState(() {
        _products[_products.indexWhere((item) => item.id == product.id)] =
            updated;
      });
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

  Future<void> _delete(InventoryProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove inventory item?'),
        content: Text('Remove "${product.name}" from your inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteProduct(product.id);
      if (mounted) {
        setState(() {
          _products.removeWhere((item) => item.id == product.id);
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory'),
        actions: [
          IconButton(
            tooltip: 'Add inventory item',
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        onPressed: () => _openForm(),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(showLoading: false),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _InventoryMessage(
        message: _error!,
        action: TextButton(
          onPressed: _loadProducts,
          child: const Text('Try again'),
        ),
      );
    }
    if (_products.isEmpty) {
      return const _InventoryMessage(
        message: 'Your inventory is empty. Add an item to start selling.',
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InventoryProductCard(
            product: product,
            showSupplier: false,
            showOwnerStockStatus: true,
            onTap: () => _openForm(product),
            actions: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit item',
                  onPressed: () => _openForm(product),
                  icon: const Icon(Icons.edit_outlined),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') _openForm(product);
                    if (action == 'delete') _delete(product);
                    if (action == 'toggle') {
                      _setAvailable(product, !product.available);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(product.available ? 'Unpublish' : 'Publish'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Remove')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InventoryProductService get _service => _productService!;
}

class _InventoryMessage extends StatelessWidget {
  const _InventoryMessage({required this.message, this.action});

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
