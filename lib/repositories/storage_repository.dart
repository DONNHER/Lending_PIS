import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  final SupabaseClient _client;
  static const String _bucketName = 'consignee-documents';

  const StorageRepository(this._client);

  /// Upload file bytes directly to Supabase Storage.
  Future<String> uploadFile({
  required List<int> fileBytes,
  required String fileName,
  required String folder,
}) async {
  final filePath = '$folder/$fileName';
  try {
    debugPrint('=== UPLOAD ATTEMPT ===');
    debugPrint('Bucket: $_bucketName');
    debugPrint('Path: $filePath');
    debugPrint('Bytes length: ${fileBytes.length}');
    debugPrint('Auth user: ${_client.auth.currentUser?.id}');
    debugPrint('Auth session: ${_client.auth.currentSession?.accessToken != null ? 'HAS TOKEN' : 'NO TOKEN'}');

    await _client.storage
        .from(_bucketName)
        .uploadBinary(
          filePath,
          Uint8List.fromList(fileBytes),
          fileOptions: const FileOptions(upsert: true),
        );

    final url = _client.storage.from(_bucketName).getPublicUrl(filePath);
    debugPrint('Upload success: $url');
    return url;
  } on StorageException catch (e) {
    debugPrint('=== STORAGE EXCEPTION ===');
    debugPrint('Message: ${e.message}');
    debugPrint('Status: ${e.statusCode}');
    debugPrint('Error: ${e.error}');
    rethrow;
  } catch (e) {
    debugPrint('=== UNEXPECTED ERROR ===');
    debugPrint('$e');
    rethrow;
  }
}

  /// Delete a file from storage using its public URL.
  Future<void> deleteFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final publicIndex = pathSegments.indexOf('public');

      if (publicIndex != -1 && publicIndex + 2 < pathSegments.length) {
        final filePath = pathSegments.sublist(publicIndex + 2).join('/');
        await _client.storage.from(_bucketName).remove([filePath]);
      }
    } catch (e) {
      // Non-fatal: log and continue — a failed delete shouldn't
      // block the user from saving their record.
      debugPrint('Warning: Failed to delete file from storage: $e');
    }
  }
}
