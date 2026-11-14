import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../design_system/app_colors.dart';
import '../../auth/auth_scope.dart';
import '../models/service_model.dart';
import '../services/services_service.dart';
import '../services_keys.dart';

class ServiceFormScreen extends StatefulWidget {
  const ServiceFormScreen({
    super.key,
    this.service,
    this.servicesService,
  });

  final ServiceModel? service;
  final ServicesService? servicesService;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ServicesService _serviceApi;

  ServiceModel? _existingService;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _category;
  late final TextEditingController _priceController;
  late final TextEditingController _priceDescriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _imageUrlController;
  late bool _isActive;

  var _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _existingService = widget.service;

    _titleController = TextEditingController(text: _existingService?.title ?? '');
    _descriptionController =
        TextEditingController(text: _existingService?.description ?? '');
    _category = _existingService?.category ?? ServiceCategory.homeCare;
    _priceController = TextEditingController(
      text: _existingService?.price != null && _existingService!.price! > 0
          ? _existingService!.price!.toStringAsFixed(2)
          : '',
    );
    _priceDescriptionController =
        TextEditingController(text: _existingService?.priceDescription ?? '');
    _locationController =
        TextEditingController(text: _existingService?.location ?? '');
    _imageUrlController =
        TextEditingController(text: _existingService?.imageUrl ?? '');
    _isActive = _existingService?.isActive ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serviceApi = widget.servicesService ??
        ServicesService(api: AuthScope.of(context).api);

    final args = ModalRoute.of(context)?.settings.arguments;
    if (_existingService == null && args is ServiceModel) {
      _existingService = args;
      _titleController.text = args.title;
      _descriptionController.text = args.description;
      _category = args.category;
      if (args.price != null && args.price! > 0) {
        _priceController.text = args.price!.toStringAsFixed(2);
      }
      _priceDescriptionController.text = args.priceDescription ?? '';
      _locationController.text = args.location ?? '';
      _imageUrlController.text = args.imageUrl ?? '';
      _isActive = args.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _priceDescriptionController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a service title.';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters.';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a service description.';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final priceParsed = double.tryParse(_priceController.text.trim());
    final priceDescription = _priceDescriptionController.text.trim();
    final location = _locationController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    try {
      if (_existingService == null) {
        await _serviceApi.createService(
          title: title,
          description: description,
          category: _category,
          price: (priceParsed != null && priceParsed > 0) ? priceParsed : null,
          priceDescription: priceDescription.isEmpty ? null : priceDescription,
          location: location.isEmpty ? null : location,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          isActive: _isActive,
        );
      } else {
        await _serviceApi.updateService(
          id: _existingService!.id,
          title: title,
          description: description,
          category: _category,
          price: (priceParsed != null && priceParsed > 0) ? priceParsed : null,
          priceDescription: priceDescription.isEmpty ? null : priceDescription,
          location: location.isEmpty ? null : location,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          isActive: _isActive,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _existingService == null
                ? 'Service created successfully!'
                : 'Service updated successfully!',
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
        _errorMessage = 'An error occurred while saving. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _existingService != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Service' : 'Create Service'),
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
                    color: AppColors.error.withOpacity(0.1),
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
              Text('Title *', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                key: ServicesKeys.formTitle,
                controller: _titleController,
                validator: _validateTitle,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'e.g. Professional Deep Cleaning',
                ),
              ),
              const SizedBox(height: 16),
              Text('Category *', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: ServicesKeys.formCategory,
                value: ServiceCategory.all.contains(_category)
                    ? _category
                    : ServiceCategory.homeCare,
                items: ServiceCategory.all.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _category = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price (\$) ', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: ServicesKeys.formPrice,
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: '\$ ',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pricing Description', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: ServicesKeys.formPriceDescription,
                          controller: _priceDescriptionController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. per hour / flat rate',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Location', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                key: ServicesKeys.formLocation,
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Algiers Downtown',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text('Image', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _submitting
                    ? null
                    : () async {
                        final base64Image =
                            await ImagePickerHelper.pickAndConvertToBase64(
                          context,
                        );
                        if (base64Image != null && mounted) {
                          setState(() {
                            _imageUrlController.text = base64Image;
                          });
                        }
                      },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pick Image from Device'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ServicesKeys.formImageUrl,
                controller: _imageUrlController,
                validator: Validators.imageUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/image.png or pick from device',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text('Description *', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                key: ServicesKeys.formDescription,
                controller: _descriptionController,
                validator: _validateDescription,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Describe the details of your service...',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                key: ServicesKeys.formIsActive,
                contentPadding: EdgeInsets.zero,
                title: Text('Active Availability', style: theme.textTheme.titleLarge),
                subtitle: Text(
                  'Active services can be discovered and booked by customers.',
                  style: theme.textTheme.bodySmall,
                ),
                value: _isActive,
                activeColor: AppColors.secondary,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: ServicesKeys.formSaveButton,
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
