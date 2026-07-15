import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BackupSettingsViewModel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  bool _isProcessing = false;
  Map<String, dynamic> _settings = {
    'backup_day': 'Monday',
    'backup_time': '02:00',
    'backup_notify_success': true,
    'backup_notify_failure': true,
  };

  BackupSettingsViewModel(this._apiService);

  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String get backupDay => _settings['backup_day'] ?? 'Monday';
  String get backupTime => _settings['backup_time'] ?? '02:00';
  bool get notifySuccess => _toBool(_settings['backup_notify_success']) ?? true;
  bool get notifyFailure => _toBool(_settings['backup_notify_failure']) ?? true;

  bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lowered = value.toLowerCase();
      return lowered == 'true' || lowered == '1';
    }
    if (value is num) return value == 1;
    return null;
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.get('/settings/backup');
      if (response['success'] == true) {
        final List<dynamic> data = response['settings'];
        for (var item in data) {
          _settings[item['key']] = _parseValue(item['value'], item['type']);
        }
      }
    } catch (e) {
      debugPrint('Error loading backup settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  dynamic _parseValue(String value, String type) {
    if (type == 'boolean' || type == 'bool') return value.toLowerCase() == 'true' || value == '1';
    if (type == 'integer' || type == 'int') return int.tryParse(value) ?? 0;
    // Fallback for boolean-like strings even if type is 'string'
    if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
      return value.toLowerCase() == 'true';
    }
    return value;
  }

  Future<bool> updateSetting(String key, dynamic value, String type) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final response = await _apiService.post('/settings/backup', body: {
        'settings': { key: value.toString() }
      });
      if (response['success'] == true) {
        _settings[key] = value;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating backup setting: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> runManualBackup(String type) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final response = await _apiService.post('/backups/run', body: {'type': type});
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error running manual backup: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
