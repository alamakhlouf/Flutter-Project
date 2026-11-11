import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../inventory_keys.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';

class InventoryFormScreen extends StatefulWidget {
  const InventoryFormScreen({
    super.key,
    this.item,
    this.inventoryService,
  });

  final InventoryItemModel? item;
  final InventoryService? inventoryService;

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final InventoryService _inventoryApi;

  InventoryItemModel? _existingItem;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _thresholdController;

  var _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _existingItem = widget.item;

    _nameController = TextEditingController(text: _existingItem?.name ?? '');
    _descriptionController =
        TextEditingController(text: _existingItem?.description ?? '');
    _quantityController = TextEditingController(
      text: _existingItem != null ? _existingItem!.quantity.toString() : '0',
    );
    _unitController = TextEditingController(text: _existingItem?.unit ?? 'units');
    _thresholdController = TextEditingController(
      text: _existingItem?.lowStockThreshold != null
          ? _existingItem!.lowStockThreshold.toString()
          : '',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inventoryApi = widget.inventoryService ??
        InventoryService(api: AuthScope.of(context).api);

    final args = ModalRoute.of(context)?.settings.arguments;
    if (_existingItem == null && args is InventoryItemModel) {
      _existingItem = args;
      _nameController.text = args.name;
      _descriptionController.text = args.description;
      _quantityController.text = args.quantity.toString();
      _unitController.text = args.unit;
      _thresholdController.text = args.lowStockThreshold?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an item name.';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters.';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a short description.';
    }
    if (value.trim().length < 5) {
      return 'Description must be at least 5 characters.';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a quantity.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Quantity must be a whole number.';
    }
    if (parsed < 0) {
      return 'Quantity cannot be negative.';
    }
    return null;
  }

  String? _validateThreshold(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Low-stock threshold must be a whole number.';
    }
    if (parsed < 0) {
      return 'Threshold cannot be negative.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final quantity = int.parse(_quantityController.text.trim());
    final unit = _unitController.text.trim();
    final thresholdText = _thresholdController.text.trim();
    final threshold = thresholdText.isEmpty ? null : int.parse(thresholdText);

    try {
      if (_existingItem == null) {
        await _inventoryApi.createInventoryItem(
          name: name,
          description: description,
          quantity: quantity,
          unit: unit.isEmpty ? 'units' : unit,
          lowStockThreshold: threshold,
        );
      } else {
        await _inventoryApi.updateInventoryItem(
          id: _existingItem!.id,
          name: name,
          description: description,
          quantity: quantity,
          unit: unit.isEmpty ? 'units' : unit,
          lowStockThreshold: threshold,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _existingItem == null
                ? 'Inventory item saved.'
                : 'Inventory item updated.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Unable to save this inventory item. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Inventory Item' : 'Add Inventory Item'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text('Name *', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                key: InventoryKeys.formName,
                controller: _nameController,
                validator: _validateName,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'e.g. Laundry detergent'),
              ),
              const SizedBox(height: 16),
              Text('Description *', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                key: InventoryKeys.formDescription,
                controller: _descriptionController,
                validator: _validateDescription,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Briefly describe the inventory item',
                ),
              ),
              const SizedBox(height: 16),
              Text('Quantity *', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                key: InventoryKeys.formQuantity,
                controller: _quantityController,
                validator: _validateQuantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '0'),
              ),
              const SizedBox(height: 16),
              Text('Unit *', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                key: InventoryKeys.formUnit,
                controller: _unitController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a unit.';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(hintText: 'e.g. bottles, packs, kg'),
              ),
              const SizedBox(height: 16),
              Text('Low-stock threshold', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                key: InventoryKeys.formLowStockThreshold,
                controller: _thresholdController,
                validator: _validateThreshold,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Optional threshold for low stock warnings',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: InventoryKeys.formSaveButton,
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
