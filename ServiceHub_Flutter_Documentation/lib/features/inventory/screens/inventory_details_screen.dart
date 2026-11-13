import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../../reports/models/report_target.dart';
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
    if (quantity == null || !mounted) return;

    setState(() => _buying = true);
    try {
      await _service.buyProduct(product.id, quantity);
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
          : _buildDetails(context, product),
    );
  }

  Widget _buildDetails(BuildContext context, InventoryProduct product) {
    final theme = Theme.of(context);
    final user = AuthScope.of(context).user;
    final isAdmin = user.role == UserRole.admin;

    final outOfStock =
        product.quantityAvailable != null && product.quantityAvailable! <= 0;
    final status = !product.available
        ? 'Unavailable'
        : outOfStock
        ? 'Out of stock'
        : product.quantityAvailable == null
        ? 'Available'
        : product.quantityAvailable! < 5
        ? 'Low stock'
        : 'In stock';
    final statusColor = !product.available
        ? AppColors.textSecondary
        : outOfStock
        ? AppColors.error
        : product.quantityAvailable != null && product.quantityAvailable! < 5
        ? AppColors.warning
        : AppColors.success;
    final imageUrl = product.imageUrl?.trim();
    final imageUri = imageUrl == null ? null : Uri.tryParse(imageUrl);
    final validImageUrl =
        imageUri != null &&
        (imageUri.scheme == 'http' || imageUri.scheme == 'https') &&
        imageUri.host.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: AppColors.surface,
          elevation: 1,
          shadowColor: AppColors.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 190,
                width: double.infinity,
                child: validImageUrl
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        _StatusBadge(label: status, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sold by ${product.supplierName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        isAdmin ? SizedBox.shrink() : Flexible(
                          child: FilledButton.icon(
                            onPressed:
                                !isAdmin && product.available && !outOfStock && !_buying
                                ? _buy
                                : null,
                            icon: _buying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag_outlined),
                            label: Text(
                               !product.available
                                  ? 'Unavailable'
                                  : outOfStock
                                  ? 'Out of stock'
                                  : 'Buy',
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (product.quantityAvailable != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${product.quantityAvailable} available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (product.description?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            color: AppColors.surface,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          color: AppColors.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.neutral,
                      foregroundColor: AppColors.primary,
                      child: Icon(Icons.storefront_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.supplierName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isAdmin) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.createReport,
                          arguments: ReportTarget(
                            type: 'PRODUCT',
                            id: product.id,
                            title: 'Report product',
                            subtitle: product.name,
                          ),
                        ),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Report product'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.createReport,
                          arguments: ReportTarget(
                            type: 'SUPPLIER',
                            id: product.supplierId,
                            title: 'Report supplier',
                            subtitle: product.supplierName,
                          ),
                        ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Report supplier'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 52,
          color: AppColors.primary.withValues(alpha: 0.28),
        ),
      ),
    );
  }

  InventoryProductService get _service => _productService!;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
