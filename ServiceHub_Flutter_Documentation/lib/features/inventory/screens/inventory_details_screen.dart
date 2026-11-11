import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../models/inventory_product_model.dart';
import '../services/inventory_product_service.dart';

class InventoryDetailsScreen extends StatefulWidget {
  const InventoryDetailsScreen({
    super.key,
    this.product,
    this.productId,
    this.productService,
  });

  final InventoryProduct? product;
  final String? productId;
  final InventoryProductService? productService;

  @override
  State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  InventoryProductService? _productService;
  InventoryProduct? _product;
  String? _error;
  var _loading = false;
  var _buying = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loading = _product == null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productService ??=
        widget.productService ??
        InventoryProductService(api: AuthScope.of(context).api);
    if (_product == null && _error == null) _loadProduct();
  }

  Future<void> _loadProduct() async {
    final id = widget.productId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Inventory item not found.';
      });
      return;
    }

    try {
      final product = await _service.fetchProduct(id);
      if (!mounted) return;
      setState(() {
        _product = product;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load this inventory item.';
        _loading = false;
      });
    }
  }

  Future<void> _buy() async {
    final product = _product;
    if (product == null) return;
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
              if (parsed == null ||
                  parsed < 1 ||
                  (product.quantityAvailable != null &&
                      parsed > product.quantityAvailable!)) {
                return;
              }
              Navigator.pop(context, parsed);
            },
            child: const Text('Place order'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (quantity == null || !mounted) return;

    setState(() => _buying = true);
    try {
      await _service.buyProduct(product.id, quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _buying = false);
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
    final product = _product;
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : product == null
          ? const Center(child: Text('Inventory item not found.'))
          : _buildDetails(context, product, canBuy),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    InventoryProduct product,
    bool canBuy,
  ) {
    final theme = Theme.of(context);
    final outOfStock =
        product.quantityAvailable != null && product.quantityAvailable! <= 0;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              product.imageUrl!,
              height: 240,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 120,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(product.name, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          product.category,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${product.price.toStringAsFixed(2)} DZD',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          outOfStock
              ? 'Out of stock'
              : product.quantityAvailable == null
              ? 'Available'
              : '${product.quantityAvailable} available',
        ),
        const SizedBox(height: 8),
        Text('Sold by ${product.supplierName}'),
        if (product.description?.isNotEmpty == true) ...[
          const SizedBox(height: 24),
          Text('Description', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(product.description!),
        ],
        if (canBuy) ...[
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: product.available && !outOfStock && !_buying
                ? _buy
                : null,
            icon: _buying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shopping_bag_outlined),
            label: Text(outOfStock ? 'Out of stock' : 'Buy'),
          ),
        ],
      ],
    );
  }

  InventoryProductService get _service => _productService!;
}
