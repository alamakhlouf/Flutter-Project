import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  const ImagePickerHelper._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndConvertToBase64(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = image.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      debugPrint('[ImagePickerHelper] Error picking image: $e');
      return null;
    }
  }
}
