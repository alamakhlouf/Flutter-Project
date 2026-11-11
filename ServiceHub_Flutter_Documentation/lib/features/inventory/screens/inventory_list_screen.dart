import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../inventory_keys.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key, this.inventoryService});

  final InventoryService? inventoryService;

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  late final InventoryService _serviceApi;

  var _loading = true;
  String? _error;
  List<InventoryItemModel> _items = <InventoryItemModel>[];
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serviceApi = widget.inventoryService ??
        InventoryService(api: AuthScope.of(context).api);
    if (_loading && _items.isEmpty && _error == null) {
      _loadInventory();
    }
  }

  Future<void> _loadInventory({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await _serviceApi.fetchMyInventory();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = items;
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
        _error = 'Unable to load your inventory. Try again.';
      });
    }
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(context).pushNamed(AppRoutes.createInventory);
    if (created == true && mounted) {
      _loadInventory();
    }
  }

  Future<void> _openEditForm(InventoryItemModel item) async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.editInventory,
      arguments: item,
    );
    if (updated == true && mounted) {
      _loadInventory();
    }
  }

  Future<void> _deleteItem(InventoryItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete inventory item?'),
        content: Text(
          'This will permanently remove "${item.name}" from your inventory.',
        ),
        actions: [
          TextButton(
            key: InventoryKeys.cancelDeleteButton,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: InventoryKeys.confirmDeleteButton,
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _serviceApi.deleteInventoryItem(item.id);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((element) => element.id == item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.name}" deleted from inventory.'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateQuantity(InventoryItemModel item) async {
    final controller = TextEditingController(text: item.quantity.toString());
    final newQuantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update quantity'),
        content: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Quantity'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a quantity.';
            }
            final parsed = int.tryParse(value.trim());
            if (parsed == null || parsed < 0) {
              return 'Quantity cannot be negative.';
            }
            return null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: InventoryKeys.updateQuantityButton(item.id),
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0) {
                return;
              }
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newQuantity == null || !mounted) return;

    try {
      final updated = await _serviceApi.updateQuantity(
        id: item.id,
        quantity: newQuantity,
      );
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere((element) => element.id == item.id);
        if (index != -1) {
          _items[index] = updated;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredItems = _items
        .where(
          (item) => item.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory'),
        actions: [
          IconButton(
            key: InventoryKeys.createInventoryButton,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add inventory item',
            onPressed: _openCreateForm,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
        onPressed: _openCreateForm,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadInventory(showLoading: false),
        child: _buildBody(theme, filteredItems),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, List<InventoryItemModel> filteredItems) {
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
              Text('Unable to Load Inventory', style: theme.textTheme.titleLarge),
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
                key: InventoryKeys.inventoryRetryButton,
                onPressed: _loadInventory,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          key: InventoryKeys.inventorySearchInput,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search inventory',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 16),
        if (filteredItems.isEmpty)
          _emptyState(theme)
        else
          ...filteredItems.map((item) => _InventoryCard(
                item: item,
                onEdit: () => _openEditForm(item),
                onDelete: () => _deleteItem(item),
                onUpdateQuantity: () => _updateQuantity(item),
              )),
      ],
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('No inventory items yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add stock items to track availability and low-stock alerts.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateQuantity,
  });

  final InventoryItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdateQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: InventoryKeys.inventoryCard(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  item.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: item.status.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quantity: ${item.quantity} ${item.unit}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (item.lowStockThreshold != null)
                Text(
                  'Threshold: ${item.lowStockThreshold}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: InventoryKeys.editInventoryButton(item.id),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: InventoryKeys.updateQuantityButton(item.id),
                  onPressed: onUpdateQuantity,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Stock'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: InventoryKeys.deleteInventoryAction(item.id),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                tooltip: 'Delete item',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
