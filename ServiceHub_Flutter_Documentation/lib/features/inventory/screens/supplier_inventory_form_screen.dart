import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/auth_scope.dart';
import '../models/inventory_product_model.dart';
import '../services/inventory_product_service.dart';

class SupplierInventoryFormScreen extends StatefulWidget {
  const SupplierInventoryFormScreen({
    super.key,
    this.productService,
    this.product,
  });

  final InventoryProductService? productService;
  final InventoryProduct? product;

  @override
  State<SupplierInventoryFormScreen> createState() =>
      _SupplierInventoryFormScreenState();
}

class _SupplierInventoryFormScreenState
    extends State<SupplierInventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  InventoryProductService? _productService;
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _descriptionController;
  var _available = true;
  var _saving = false;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productService ??=
        widget.productService ??
        InventoryProductService(api: AuthScope.of(context).api);
  }

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: product?.quantityAvailable?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _available = product?.available ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.saveProduct(
        id: widget.product?.id,
        name: _nameController.text,
        category: _categoryController.text,
        price: double.parse(_priceController.text.trim()),
        description: _descriptionController.text,
        quantityAvailable: _quantityController.text.trim().isEmpty
            ? null
            : int.parse(_quantityController.text.trim()),
        available: _available,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Unable to save this inventory item. Try again.';
      });
    }
  }

  String? _requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Enter $label.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Inventory Item' : 'Add Inventory Item'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: (value) => _requiredText(value, 'an item name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => _requiredText(value, 'a category'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price (DZD)'),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null || price < 0) {
                    return 'Enter a valid non-negative price.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity available',
                  helperText: 'Leave blank if quantity is not tracked.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final quantity = int.tryParse(value.trim());
                  if (quantity == null || quantity < 0) {
                    return 'Enter a non-negative whole number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available for purchase'),
                value: _available,
                onChanged: (value) => setState(() => _available = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Add item'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InventoryProductService get _service => _productService!;
}
