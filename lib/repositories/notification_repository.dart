import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiService _apiService;

  NotificationRepository(this._apiService);

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await _apiService.get('/notifications', queryParams: {'user_id': userId});
    final List<dynamic> data = response['data'] is List ? response['data'] : [];
    return data.map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<void> markAsRead(String id) async {
    await _apiService.post('/notifications/$id/mark-as-read', body: <String, dynamic>{});
  }

  Future<void> markAllAsRead(String userId) async {
    await _apiService.post('/notifications/mark-all-read', body: <String, dynamic>{'user_id': userId});
  }

  Future<void> deleteAll(String userId) async {
    await _apiService.delete('/notifications', body: <String, dynamic>{'user_id': userId});
  }
}
