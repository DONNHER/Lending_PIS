import 'dart:convert';
import 'dart:io' show Directory, File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/export_format.dart';

class ImportExportViewModel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isExporting = false;
  bool _isImporting = false;

  Map<String, dynamic>? _previewData;
  List<dynamic> _errors = [];
  List<dynamic> _duplicates = [];

  // 🎯 WEB FIX: Save file assets inside byte memory containers instead of file path links
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  int _importedCount = 0;
  int _failedCount = 0;
  String? _lastImportMessage;

  bool get isExporting => _isExporting;
  bool get isImporting => _isImporting;
  bool get isProcessing => _isExporting || _isImporting;

  Map<String, dynamic>? get previewData => _previewData;
  List<dynamic> get errors => _errors;
  List<dynamic> get duplicates => _duplicates;
  int get importedCount => _importedCount;
  int get failedCount => _failedCount;
  String? get lastImportMessage => _lastImportMessage;

  ImportExportViewModel(this._apiService);

  Future<void> exportData(String type, String format) async {
    _isExporting = true;
    notifyListeners();

    try {
      final exportConfig = ExportFormatInfo.forFormat(format);

      String baseUrl = _apiService.baseUrl;
      if (baseUrl.endsWith('/api')) baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      if (baseUrl.endsWith('/api/')) baseUrl = baseUrl.substring(0, baseUrl.length - 5);
      baseUrl = baseUrl.replaceAll(RegExp(r'/$'), '');

      final String url = '$baseUrl/api/export/$type/${exportConfig.format}';
      final String? token = await _apiService.getToken();

      if (kIsWeb) {
        debugPrint('[ImportExportViewModel] 🌐 WEB ENVIRONMENT: LAUNCHING WITH QUERY TOKEN');
        final String authenticatedUrl = token != null && token.isNotEmpty
            ? '$url?token=$token'
            : url;

        final webUri = Uri.parse(authenticatedUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[ImportExportViewModel] 📱 NATIVE APP: WRITING TO DISK LAYER');

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Accept': exportConfig.mimeType,
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode >= 400) throw Exception('Export failed with status ${response.statusCode}');

        final sanitizedType = type.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
        final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
        final fileName = '${sanitizedType}_$timestamp${exportConfig.extension}';

        final file = File('${Directory.systemTemp.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes, flush: true);

        final fileUri = Uri.file(file.path);
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[ImportExportViewModel] 🚨 FATAL EXPORT CRASH: $e');
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<bool> previewImport(String type) async {
    // 🎯 WEB FIX: Explicitly request withData: true so file picker fetches raw data stream bytes
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv', 'txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return false;

    final pickedFile = result.files.first;

    // Ensure we have read the raw bytes safely
    if (pickedFile.bytes == null) {
      debugPrint('[ImportExportViewModel] ❌ ERROR: File bytes could not be loaded.');
      return false;
    }

    _selectedFileBytes = pickedFile.bytes;
    _selectedFileName = pickedFile.name;

    _isImporting = true;
    _previewData = null;
    _errors = [];
    _duplicates = [];
    _importedCount = 0;
    _failedCount = 0;
    _lastImportMessage = null;
    notifyListeners();

    try {
      // Direct stream byte transmission
      final response = await _apiService.uploadFileBytes(
        endpoint: '/import/$type/preview',
        bytes: _selectedFileBytes!,
        fileName: _selectedFileName!,
      );

      if (response['success'] == true) {
        _previewData = response;
        _errors = response['errors'] ?? [];
        _duplicates = response['duplicates'] ?? [];
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[ImportExportViewModel] 🚨 FATAL PREVIEW RUNTIME ERROR CATCH: $e');
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<bool> confirmImport(String type, String filePath) async {
    if (_selectedFileBytes == null || _selectedFileName == null) {
      debugPrint('[ImportExportViewModel] ❌ ERROR: No active file bytes selected for confirmation step.');
      return false;
    }

    _isImporting = true;
    notifyListeners();

    try {
      final response = await _apiService.uploadFileBytes(
        endpoint: '/import/$type/confirm',
        bytes: _selectedFileBytes!,
        fileName: _selectedFileName!,
      );

      final success = response['success'] == true;
      if (success) {
        _importedCount = response['imported_count'] ?? 0;
        _failedCount = response['failed_count'] ?? 0;
        _lastImportMessage = response['message'] ?? 'Import completed';
      } else {
        _lastImportMessage = response['message'] ?? 'Import failed';
      }
      return success;
    } catch (e) {
      debugPrint('[ImportExportViewModel] 🚨 FATAL COMMIT EXPORT WRITER TRANSACTION FAILURE: $e');
      _lastImportMessage = 'Import failed';
      return false;
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }

  Future<void> downloadErrorReport() async {
    if (_errors.isEmpty) return;

    try {
      String baseUrl = _apiService.baseUrl;
      if (baseUrl.endsWith('/api')) baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      if (baseUrl.endsWith('/api/')) baseUrl = baseUrl.substring(0, baseUrl.length - 5);
      final String url = '${baseUrl.replaceAll(RegExp(r'/$'), '')}/api/import/error-report';

      final String? token = await _apiService.getToken();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'errors': _errors}),
      );

      if (response.statusCode >= 400) {
        throw Exception('Error report download failed with status ${response.statusCode}');
      }

      final fileName = 'import_errors_${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.xlsx';

      if (kIsWeb) {
        final base64Data = base64Encode(response.bodyBytes);
        final dataUri = 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Data';
        await launchUrl(Uri.parse(dataUri));
      } else {
        final file = File('${Directory.systemTemp.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes, flush: true);

        final fileUri = Uri.file(file.path);
        if (await canLaunchUrl(fileUri)) {
          await launchUrl(fileUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('[ImportExportViewModel] 🚨 ERROR DUMP DOWNLOADING FAULT CONTEXT: $e');
    }
  }

  void clearPreview() {
    _previewData = null;
    _errors = [];
    _duplicates = [];
    _selectedFileBytes = null;
    _selectedFileName = null;
    _importedCount = 0;
    _failedCount = 0;
    _lastImportMessage = null;
    notifyListeners();
  }
}