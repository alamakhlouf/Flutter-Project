import 'package:flutter/material.dart';

import '../../../core/widgets/image_renderer.dart';
import '../../../design_system/app_colors.dart';

class WorkshopImage extends StatelessWidget {
  const WorkshopImage({super.key, required this.imageUrl, this.height = 180});

  final String? imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ImageRenderer(
        imageUrl: imageUrl,
        placeholder: _placeholder(),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _placeholder() => const ColoredBox(
    color: AppColors.surface,
    child: Center(
      child: Icon(Icons.school_outlined, size: 42, color: AppColors.primary),
    ),
  );
}
