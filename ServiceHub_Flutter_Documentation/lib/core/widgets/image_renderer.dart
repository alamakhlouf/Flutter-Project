import 'dart:convert';
import 'package:flutter/material.dart';

class ImageRenderer extends StatelessWidget {
  const ImageRenderer({
    required this.imageUrl,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    super.key,
  });

  final String? imageUrl;
  final Widget placeholder;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return placeholder;
    }

    if (url.startsWith('data:image/') || url.contains('base64,')) {
      try {
        final commaIndex = url.indexOf(',');
        final base64Part = commaIndex != -1 ? url.substring(commaIndex + 1) : url;
        final cleanBase64 = base64Part.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('[ImageRenderer] Memory image error: $error');
            return placeholder;
          },
        );
      } catch (e) {
        debugPrint('[ImageRenderer] Base64 decode error: $e');
        return placeholder;
      }
    }

    final uri = Uri.tryParse(url);
    final isValid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValid) {
      return placeholder;
    }

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[ImageRenderer] Network image error: $error');
        return placeholder;
      },
    );
  }
}
