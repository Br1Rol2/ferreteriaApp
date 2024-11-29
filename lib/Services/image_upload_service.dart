// lib/Services/image_upload_service.dart

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient client;

  ImageUploadService(this.client);

  // Seleccionar una imagen desde la galería
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Subir imagen a Supabase Storage
  Future<String?> uploadImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileName = 'products/${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';

      final response = await client.storage
          .from('product_images')
          .uploadBinary(fileName, bytes);

      if (response != null) {
        print('Error uploading image: ${response}');
        return null;
      }

      final imageUrl = client.storage
          .from('product_images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }


}
