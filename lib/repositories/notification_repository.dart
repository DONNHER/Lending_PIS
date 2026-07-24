import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiService _apiService;
  final _supabase = Supabase.instance.client;

  NotificationRepository(this._apiService);

  Future<List<NotificationModel>> getNotifications(String shareholderId) async {
    final response = await _apiService.get('/notifications', queryParams: {'shareholder_id': shareholderId});
    final List<dynamic> data = response['data'] is List ? response['data'] : [];
    return data.map((json) => NotificationModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  Future<void> markAsRead(String id) async {
    try {
      // 🚀 Directly persist the read state in Supabase
      await _supabase
          .from('notifications')
          .update({'is_unread': false}) // Change to {'is_read': true} if your column is named is_read
          .eq('id', id);

      // Keep backend API sync call as a fallback/secondary trigger
      await _apiService.post('/notifications/$id/mark-as-read', body: <String, dynamic>{});
    } catch (e) {
      debugPrint('DEBUG: [NotificationRepository] Error updating notification read state in Supabase: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead(String shareholderId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_unread': false})
          .eq('shareholder_id', shareholderId);

      await _apiService.post('/notifications/mark-all-read', body: <String, dynamic>{'shareholder_id': shareholderId});
    } catch (e) {
      debugPrint('DEBUG: [NotificationRepository] Error bulk updating notifications in Supabase: $e');
      rethrow;
    }
  }

  Future<void> deleteAll(String shareholderId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('shareholder_id', shareholderId);

      await _apiService.delete('/notifications', body: <String, dynamic>{'shareholder_id': shareholderId});
    } catch (e) {
      debugPrint('DEBUG: [NotificationRepository] Error deleting notifications in Supabase: $e');
      rethrow;
    }
  }
}