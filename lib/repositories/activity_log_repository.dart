import '../services/api_service.dart';
import '../models/activity_log_model.dart';

class ActivityLogRepository {
  final ApiService _apiService;

  ActivityLogRepository(this._apiService);

  Future<void> logActivity({
    required String action,
    required String details,
    String? type,
    String? ipAddress,
    String? deviceInfo,
    String? stackTrace,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    try {
      await _apiService.post(
        '/activity-logs', 
        body: {
          'action': action,
          'details': details,
          'type': type ?? 'info',
          if (ipAddress != null) 'ip_address': ipAddress,
          if (deviceInfo != null) 'device_info': deviceInfo,
          if (stackTrace != null) 'stack_trace': stackTrace,
          if (oldValues != null) 'old_values': oldValues,
          if (newValues != null) 'new_values': newValues,
        },
        triggerUnauthorized: false,
      );
    } catch (e) {
      // Ignore logging errors to prevent blocking main actions
    }
  }

  Future<List<ActivityLog>> getLogs() async {
    final response = await _apiService.get('/activity-logs');
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => ActivityLog.fromJson(json)).toList();
  }
}
