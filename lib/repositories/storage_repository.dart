import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageRepository {
  final ApiService _api;

  const StorageRepository(this._api);

  Future<String> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      final token = await _api.getToken();
      final uri = Uri.parse('${_api.baseUrl}/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
      request.fields['folder'] = folder;
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('StorageRepo Error: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    // Implement if needed
  }
}
