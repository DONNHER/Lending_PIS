import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  StorageRepository();

  Future<String> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      debugPrint('DEBUG: [StorageRepository] --- UPLOAD START ---');
      debugPrint('DEBUG: [StorageRepository] Target Bucket: "$folder"');
      
      // Check Auth Status
      final user = _supabase.auth.currentUser;
      final session = _supabase.auth.currentSession;
      debugPrint('DEBUG: [StorageRepository] Supabase Auth User: ${user?.id ?? "NONE (Anonymous)"}');
      debugPrint('DEBUG: [StorageRepository] Supabase Session Active: ${session != null}');

      // Note: Listing buckets often requires extra permissions. 
      // We'll skip the debug list and just try the upload.

      await _supabase.storage.from(folder).uploadBinary(
            fileName,
            Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              // Set upsert to false to avoid requiring SELECT/UPDATE permissions for the 'anon' role
              upsert: false,
            ),
          );

      final String publicUrl = _supabase.storage.from(folder).getPublicUrl(fileName);
      debugPrint('DEBUG: [StorageRepository] UPLOAD SUCCESS! URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('DEBUG: [StorageRepository] UPLOAD FAILED: $e');
      
      // Handle "The resource already exists" if upsert is false
      if (e.toString().contains('already exists')) {
        final String publicUrl = _supabase.storage.from(folder).getPublicUrl(fileName);
        return publicUrl;
      }

      if (e is StorageException && e.message.contains('Bucket not found')) {
        throw Exception('Bucket "$folder" not found. Please ensure it is created in Supabase.');
      }
      
      throw Exception('Upload Error: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final segments = uri.pathSegments;
      final publicIndex = segments.indexOf('public');
      if (publicIndex != -1 && segments.length > publicIndex + 2) {
        final bucket = segments[publicIndex + 1];
        final path = segments.sublist(publicIndex + 2).join('/');
        await _supabase.storage.from(bucket).remove([path]);
      }
    } catch (e) {
      debugPrint('DEBUG: [StorageRepository] Delete Error: $e');
    }
  }
}
