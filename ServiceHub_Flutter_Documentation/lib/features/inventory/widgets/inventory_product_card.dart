import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';
import '../models/inventory_product_model.dart';

class InventoryProductCard extends StatelessWidget {
  const InventoryProductCard({
    super.key,
    required this.product,
    required this.actions,
    this.showSupplier = true,
    this.showOwnerStockStatus = false,
    this.onTap,
  });

  final InventoryProduct product;
  final Widget actions;
  final bool showSupplier;
  final bool showOwnerStockStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = product.imageUrl?.trim();
    final uri = imageUrl == null ? null : Uri.tryParse(imageUrl);
    final validImageUrl =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: AppColors.surface,
          elevation: 1,
          shadowColor: AppColors.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 144,
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
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (showSupplier &&
                          product.supplierName.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.supplierName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (product.description?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          product.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final price = Column(
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
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );

                          if (constraints.maxWidth < 300) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                price,
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: actions,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: price),
                              actions,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showOwnerStockStatus) ...[
          const SizedBox(height: 8),
          _ownerStockStatus(theme),
        ],
      ],
    );
  }

  Widget _imagePlaceholder() {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 38,
          color: AppColors.primary.withValues(alpha: 0.28),
        ),
      ),
    );
  }

  Widget _ownerStockStatus(ThemeData theme) {
    final status = !product.available
        ? 'Unavailable'
        : product.quantityAvailable == 0
        ? 'Out of stock'
        : product.quantityAvailable == null
        ? 'Available'
        : product.quantityAvailable! < 5
        ? 'Low stock'
        : 'In stock';
    final color = !product.available
        ? AppColors.textSecondary
        : product.quantityAvailable == 0
        ? AppColors.error
        : product.quantityAvailable != null && product.quantityAvailable! < 5
        ? AppColors.warning
        : AppColors.success;
    final quantity = product.quantityAvailable;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: color),
              const SizedBox(width: 6),
              Text(
                status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (quantity != null)
          Text(
            '$quantity available',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
