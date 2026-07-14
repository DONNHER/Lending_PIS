import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiService _apiService;

  NotificationRepository(this._apiService);

  Future<List<NotificationModel>> getNotifications(String shareholderId) async {
    final response = await _apiService.get('/notifications', queryParams: {'shareholder_id': shareholderId});
    final List<dynamic> data = response['data'] is List ? response['data'] : [];
    return data.map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<void> markAsRead(String id) async {
    await _apiService.post('/notifications/$id/mark-as-read', body: <String, dynamic>{});
  }

  Future<void> markAllAsRead(String shareholderId) async {
    await _apiService.post('/notifications/mark-all-read', body: <String, dynamic>{'shareholder_id': shareholderId});
  }

  Future<void> deleteAll(String shareholderId) async {
    await _apiService.delete('/notifications', body: <String, dynamic>{'shareholder_id': shareholderId});
  }
}
