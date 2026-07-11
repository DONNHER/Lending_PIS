import '../services/api_service.dart';

class ActivityLogRepository {
  final ApiService _apiService;

  ActivityLogRepository(this._apiService);

  Future<void> logActivity({
    required String action,
    required String details,
    String? type,
  }) async {
    try {
      await _apiService.post(
        '/activity-logs', 
        body: {
          'action': action,
          'details': details,
          'type': type ?? 'info',
        },
        triggerUnauthorized: false,
      );
    } catch (e) {
      // Ignore logging errors to prevent blocking main actions
    }
  }

  Future<List<dynamic>> getLogs() async {
    final response = await _apiService.get('/activity-logs');
    return response['data'] ?? [];
  }
}
