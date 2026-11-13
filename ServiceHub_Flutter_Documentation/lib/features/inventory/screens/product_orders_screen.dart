import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../../auth/models/auth_user.dart';
import '../models/product_order_model.dart';
import '../services/product_order_service.dart';

class ProductOrdersScreen extends StatefulWidget {
  const ProductOrdersScreen({super.key, this.orderService});

  final ProductOrderService? orderService;

  @override
  State<ProductOrdersScreen> createState() => _ProductOrdersScreenState();
}

class _ProductOrdersScreenState extends State<ProductOrdersScreen> {
  ProductOrderService? _service;
  List<ProductOrderModel> _orders = const [];
  String? _error;
  bool _loading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _service =
        widget.orderService ??
        ProductOrderService(api: AuthScope.of(context).api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _service!.fetchMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
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
        _error = 'Unable to load product orders.';
        _loading = false;
      });
    }
  }

  Future<void> _openOrder(ProductOrderModel order) async {
    final updated = await Navigator.of(context).push<ProductOrderModel>(
      MaterialPageRoute<ProductOrderModel>(
        settings: const RouteSettings(name: AppRoutes.productOrderDetails),
        builder: (_) => ProductOrderDetailsScreen(
          order: order,
          isSupplier: AuthScope.of(context).user.role == UserRole.supplier,
          orderService: _service!,
        ),
      ),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        _orders = [
          for (final item in _orders)
            if (item.id == updated.id) updated else item,
        ];
      });
    } else {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupplier = AuthScope.of(context).user.role == UserRole.supplier;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSupplier ? 'Incoming product orders' : 'My product orders',
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _LoadError(message: _error!, onRetry: _load)
          : _orders.isEmpty
          ? Center(
              child: Text(
                isSupplier
                    ? 'New customer orders will appear here.'
                    : 'Your product orders will appear here.',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return _OrderCard(
                    order: order,
                    showSupplierName:
                        AuthScope.of(context).user.role != UserRole.supplier,
                    onTap: () => _openOrder(order),
                  );
                },
              ),
            ),
    );
  }
}

class ProductOrderDetailsScreen extends StatefulWidget {
  const ProductOrderDetailsScreen({
    super.key,
    required this.order,
    required this.isSupplier,
    required this.orderService,
  });

  final ProductOrderModel order;
  final bool isSupplier;
  final ProductOrderService orderService;

  @override
  State<ProductOrderDetailsScreen> createState() =>
      _ProductOrderDetailsScreenState();
}

class _ProductOrderDetailsScreenState extends State<ProductOrderDetailsScreen> {
  late ProductOrderModel _order = widget.order;
  bool _busy = false;

  Future<void> _changeStatus(ProductOrderStatus status) async {
    await _runAction(() => widget.orderService.updateStatus(_order.id, status));
  }

  Future<void> _cancel() async {
    await _runAction(() => widget.orderService.cancel(_order.id));
  }

  Future<void> _runAction(Future<ProductOrderModel> Function() action) async {
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _order = updated;
        _busy = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update this order. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _OrderCard(order: order, showSupplierName: !widget.isSupplier),
          const SizedBox(height: 16),
          if (widget.isSupplier && order.customerName?.isNotEmpty == true) ...[
            Card(
              color: AppColors.surface,
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Customer'),
                subtitle: Text(order.customerName!),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final item in order.items) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text('${item.productName} × ${item.quantity}'),
                        ),
                        Text('\$${item.lineTotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(child: Text('Total')),
                      Text('\$${order.totalAmount.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (widget.isSupplier) ..._supplierActions(order),
          if (!widget.isSupplier &&
              (order.status == ProductOrderStatus.pending ||
                  order.status == ProductOrderStatus.accepted))
            OutlinedButton.icon(
              onPressed: _busy ? null : _cancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel order'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(_order),
            child: const Text('Back to orders'),
          ),
        ],
      ),
    );
  }

  List<Widget> _supplierActions(ProductOrderModel order) {
    if (order.status == ProductOrderStatus.pending) {
      return [
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _changeStatus(ProductOrderStatus.accepted),
          icon: const Icon(Icons.check),
          label: const Text('Accept order'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _changeStatus(ProductOrderStatus.rejected),
          icon: const Icon(Icons.close),
          label: const Text('Reject order'),
        ),
      ];
    }
    if (order.status == ProductOrderStatus.accepted) {
      return [
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _changeStatus(ProductOrderStatus.processing),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Mark processing'),
        ),
      ];
    }
    if (order.status == ProductOrderStatus.processing) {
      return [
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _changeStatus(ProductOrderStatus.completed),
          icon: const Icon(Icons.done_all),
          label: const Text('Mark completed'),
        ),
      ];
    }
    return [];
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.onTap,
    this.showSupplierName = false,
  });

  final ProductOrderModel order;
  final VoidCallback? onTap;
  final bool showSupplierName;

  @override
  Widget build(BuildContext context) {
    final createdAt = order.createdAt?.toLocal();
    final date = createdAt == null
        ? null
        : '${createdAt.day.toString().padLeft(2, '0')}/'
              '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    final statusColor = switch (order.status) {
      ProductOrderStatus.pending => AppColors.warning,
      ProductOrderStatus.accepted ||
      ProductOrderStatus.processing => AppColors.info,
      ProductOrderStatus.completed => AppColors.success,
      ProductOrderStatus.rejected => AppColors.error,
      ProductOrderStatus.cancelled => AppColors.textSecondary,
    };
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (date != null) Text('Placed $date'),
              if (showSupplierName && order.supplierName?.isNotEmpty == true)
                Text('From ${order.supplierName}'),
              const SizedBox(height: 5),
              Text(
                order.status.label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${order.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
