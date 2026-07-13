import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
      final String fullPath = '$path/$fileName';

      await _supabase.storage.from(bucket).upload(fullPath, file);
      
      final String publicUrl = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadBytes({
    required String bucket,
    required String path,
    required String fileName,
    required dynamic bytes, // Uint8List
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fullPath = '$path/${timestamp}_$fileName';

      debugPrint('DEBUG: [StorageRepository] Uploading bytes to bucket: $bucket, path: $fullPath');

      await _supabase.storage.from(bucket).uploadBinary(fullPath, bytes);
      
      final String publicUrl = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      debugPrint('DEBUG: [StorageRepository] Upload success. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('DEBUG: [StorageRepository] Upload failed: $e');
      return null;
    }
  }

  Future<void> deleteFile(String url) async {
    // Logic to extract path from URL and delete from Supabase
  }
}
