import 'package:flutter/material.dart';

import '../../../design_system/app_colors.dart';

class WorkshopImage extends StatelessWidget {
  const WorkshopImage({super.key, required this.imageUrl, this.height = 180});

  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final uri = url == null ? null : Uri.tryParse(url);
    final validUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: validUrl
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => const ColoredBox(
    color: AppColors.surface,
    child: Center(
      child: Icon(Icons.school_outlined, size: 42, color: AppColors.primary),
    ),
  );
}
