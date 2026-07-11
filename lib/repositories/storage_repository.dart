import 'dart:io';
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

  Future<void> deleteFile(String url) async {
    // Logic to extract path from URL and delete from Supabase
  }
}
