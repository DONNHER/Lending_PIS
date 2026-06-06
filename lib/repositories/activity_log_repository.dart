import 'package:flutter/foundation.dart';
import '../models/activity_log_model.dart';
import '../services/api_service.dart';

class ActivityLogRepository {
  final ApiService _api;

  const ActivityLogRepository(this._api);

  Future<List<ActivityLogModel>> getActivityLogs({
    int offset = 0,
    int limit = 10,
    String? dateFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? shareholderId,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
      };

      if (shareholderId != null) queryParams['shareholder_id'] = shareholderId;
      if (userId != null) queryParams['user_id'] = userId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (dateFilter != null) queryParams['date_filter'] = dateFilter;

      final response = await _api.get('activity-logs', queryParams: queryParams);
      
      final List<dynamic> data = response['data'];
      return data.map((json) => ActivityLogModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('ActivityLogRepo Error: $e');
      return [];
    }
  }

  Future<int> getActivityLogsCount({
    String? userId, 
    String? shareholderId,
    String? dateFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (shareholderId != null) queryParams['shareholder_id'] = shareholderId;
      if (userId != null) queryParams['user_id'] = userId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (dateFilter != null) queryParams['date_filter'] = dateFilter;

      final response = await _api.get('activity-logs/count', queryParams: queryParams);
      return response['total'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting activity logs count: $e');
      return 0;
    }
  }

  Future<void> logActivity(ActivityLogModel log) async {
    try {
      await _api.post('activity-logs', body: log.toJson());
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  Future<void> deleteActivityLog(String id) async {
    try {
      await _api.delete('activity-logs/$id');
    } catch (e) {
      debugPrint('Error deleting activity log: $e');
    }
  }
}
