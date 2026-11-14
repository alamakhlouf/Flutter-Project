import 'package:flutter/material.dart';

import '../../../core/widgets/image_renderer.dart';
import '../../../design_system/app_colors.dart';

import '../models/service_model.dart';
import '../services_keys.dart';

/// Pill badge indicating Active or Inactive availability status.
class ServiceStatusBadge extends StatelessWidget {
  const ServiceStatusBadge({
    super.key,
    required this.isActive,
    this.compact = false,
  });

  final bool isActive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? AppColors.success : AppColors.textSecondary;
    final bgColor = isActive
        ? const Color(0xE6EBF5EE)
        : const Color(0xFFEEEEEE);
    final text = isActive ? 'Active' : 'Inactive';
    final icon = isActive
        ? Icons.check_circle_outline
        : Icons.pause_circle_outline;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style:
                (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Category chip used in filters and cards.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.keyOverride,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Key? keyOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: keyOverride ?? ServicesKeys.categoryChip(label),
        selected: isSelected,
        label: Text(label),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: isSelected ? AppColors.surface : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.neutral,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) => onSelected(),
        showCheckmark: false,
      ),
    );
  }
}

/// Service card displayed in the catalog or provider dashboard.
class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.isProviderView = false,
    this.onToggleActive,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
  });

  final ServiceModel service;
  final VoidCallback onTap;
  final bool isProviderView;
  final ValueChanged<bool>? onToggleActive;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: ServicesKeys.serviceCard(service.id),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _ServiceHeaderImage(
                  imageUrl: service.imageUrl,
                  category: service.category,
                ),
                if (!isProviderView && onToggleFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          service.favorite ? Icons.favorite : Icons.favorite_border,
                          color: service.favorite ? AppColors.error : AppColors.primary,
                          size: 20,
                        ),
                        onPressed: onToggleFavorite,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        tooltip: service.favorite ? 'Remove from favorites' : 'Add to favorites',
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.category.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isProviderView)
                        ServiceStatusBadge(
                          isActive: service.isActive,
                          compact: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    service.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  if (service.providerName != null && !isProviderView) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: AppColors.neutral,
                          child: Text(
                            service.providerName!.isEmpty
                                ? 'P'
                                : service.providerName![0].toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'by ${service.providerName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                  ],
                  if (service.location != null &&
                      service.location!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service.location!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.price != null && service.price! > 0
                                  ? 'Starting at'
                                  : 'Pricing',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              service.formattedPrice,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isProviderView)
                        FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: const Text('View details'),
                        ),
                    ],
                  ),
                  if (isProviderView) ...[
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      children: [
                        Text(
                          service.isActive ? 'Active' : 'Inactive',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          key: ServicesKeys.toggleActiveSwitch(service.id),
                          value: service.isActive,
                          activeThumbColor: AppColors.secondary,
                          onChanged: onToggleActive,
                        ),
                        const Spacer(),
                        IconButton(
                          key: ServicesKeys.editServiceButton(service.id),
                          icon: const Icon(Icons.edit_outlined),
                          color: AppColors.primary,
                          tooltip: 'Edit service',
                          onPressed: onEdit,
                        ),
                        IconButton(
                          key: ServicesKeys.deleteServiceAction(service.id),
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.error,
                          tooltip: 'Delete service',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceHeaderImage extends StatelessWidget {
  const _ServiceHeaderImage({required this.imageUrl, required this.category});

  final String? imageUrl;
  final String category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageRenderer(
            imageUrl: imageUrl,
            placeholder: _placeholder(category),
            fit: BoxFit.cover,
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(String category) {
    IconData icon;
    switch (category) {
      case ServiceCategory.cleaning:
        icon = Icons.cleaning_services_outlined;
        break;
      case ServiceCategory.plumbing:
        icon = Icons.plumbing_outlined;
        break;
      case ServiceCategory.electrical:
        icon = Icons.electrical_services_outlined;
        break;
      case ServiceCategory.tutoring:
        icon = Icons.school_outlined;
        break;
      case ServiceCategory.beauty:
        icon = Icons.spa_outlined;
        break;
      case ServiceCategory.fitness:
        icon = Icons.fitness_center_outlined;
        break;
      case ServiceCategory.event:
        icon = Icons.event_outlined;
        break;
      case ServiceCategory.homeCare:
        icon = Icons.home_repair_service_outlined;
        break;
      default:
        icon = Icons.miscellaneous_services_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: AppColors.primary.withValues(alpha: 0.38),
          ),
        ],
      ),
    );
  }
}

/// Dialog asking confirmation before deleting a service.
class DeleteServiceDialog extends StatelessWidget {
  const DeleteServiceDialog({super.key, required this.serviceTitle});

  final String serviceTitle;

  static Future<bool> show(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteServiceDialog(serviceTitle: title),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Delete Service'),
      content: Text(
        'Are you sure you want to delete "$serviceTitle"? This action cannot be undone.',
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        OutlinedButton(
          key: ServicesKeys.cancelDeleteButton,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: ServicesKeys.confirmDeleteButton,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.surface,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

/// Bottom sheet dialog to set catalog filters.
class ServiceFilterSheet extends StatefulWidget {
  const ServiceFilterSheet({
    super.key,
    required this.selectedCategory,
    required this.maxPrice,
    required this.location,
    required this.onApply,
  });

  final String? selectedCategory;
  final double? maxPrice;
  final String? location;
  final void Function({String? category, double? maxPrice, String? location})
  onApply;

  static Future<void> show({
    required BuildContext context,
    required String? selectedCategory,
    required double? maxPrice,
    required String? location,
    required void Function({
      String? category,
      double? maxPrice,
      String? location,
    })
    onApply,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ServiceFilterSheet(
          selectedCategory: selectedCategory,
          maxPrice: maxPrice,
          location: location,
          onApply: onApply,
        ),
      ),
    );
  }

  @override
  State<ServiceFilterSheet> createState() => _ServiceFilterSheetState();
}

class _ServiceFilterSheetState extends State<ServiceFilterSheet> {
  late String _category;
  late final TextEditingController _priceController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory ?? 'All';
    _priceController = TextEditingController(
      text: widget.maxPrice != null && widget.maxPrice! > 0
          ? widget.maxPrice!.toStringAsFixed(0)
          : '',
    );
    _locationController = TextEditingController(text: widget.location ?? '');
  }

  @override
  void dispose() {
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _category = 'All';
      _priceController.clear();
      _locationController.clear();
    });
  }

  void _submit() {
    final parsedPrice = double.tryParse(_priceController.text.trim());
    widget.onApply(
      category: _category == 'All' ? null : _category,
      maxPrice: (parsedPrice != null && parsedPrice > 0) ? parsedPrice : null,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['All', ...ServiceCategory.all];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filter Services', style: theme.textTheme.headlineMedium),
              const Spacer(),
              TextButton(
                key: ServicesKeys.filterResetButton,
                onPressed: _reset,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Category', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ServicesKeys.filterCategoryDropdown,
            value: categories.contains(_category) ? _category : 'All',
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: categories.map((cat) {
              return DropdownMenuItem<String>(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 16),
          Text('Max Price (\$)', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          TextField(
            key: ServicesKeys.filterMaxPriceInput,
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'e.g. 100',
              prefixText: '\$ ',
            ),
          ),
          const SizedBox(height: 16),
          Text('Location', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          TextField(
            key: ServicesKeys.filterLocationInput,
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: 'e.g. Algiers',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: ServicesKeys.filterApplyButton,
            onPressed: _submit,
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
