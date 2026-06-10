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

      // Attempt to list buckets to verify connectivity
      try {
        final buckets = await _supabase.storage.listBuckets();
        debugPrint('DEBUG: [StorageRepository] Visible Buckets: ${buckets.map((e) => e.id).toList()}');
      } catch (e) {
        debugPrint('DEBUG: [StorageRepository] Could not list buckets (likely permission issue): $e');
      }

      await _supabase.storage.from(folder).uploadBinary(
            fileName,
            Uint8List.fromList(fileBytes),
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final String publicUrl = _supabase.storage.from(folder).getPublicUrl(fileName);
      debugPrint('DEBUG: [StorageRepository] UPLOAD SUCCESS! URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('DEBUG: [StorageRepository] UPLOAD FAILED: $e');
      if (e is StorageException && e.message.contains('Bucket not found')) {
        throw Exception('Bucket "$folder" not found or not accessible. If you use Laravel Auth, update Supabase Policy to allow "anon" role.');
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
