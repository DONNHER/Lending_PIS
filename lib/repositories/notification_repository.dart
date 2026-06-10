import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationRepository {
  final ApiService _api;

  NotificationRepository(this._api);

  /// Laravel usually handles real-time via Pusher/WebSockets.
  /// For this migration, we'll use standard API polling or manual refresh.
  Stream<List<NotificationModel>> subscribeToNotifications({
    required String shareholderId,
  }) {
    // Basic implementation that polls every 30 seconds for new data
    // Real production should use Laravel Reverb or Pusher
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      debugPrint('DEBUG: [NotificationRepo] Periodic poll for shareholderId: $shareholderId');
      return await getNotifications(shareholderId);
    });
  }

  Future<List<NotificationModel>> getNotifications(String shareholderId) async {
    try {
      debugPrint('DEBUG: [NotificationRepo] GET /notifications?shareholder_id=$shareholderId');
      final response = await _api.get('notifications', queryParams: {'shareholder_id': shareholderId});
      
      debugPrint('DEBUG: [NotificationRepo] API Response received: $response');
      
      final List<dynamic> data = response['data'] ?? [];
      debugPrint('DEBUG: [NotificationRepo] Found ${data.length} notification items in response');
      
      return data.map((json) {
        try {
          return NotificationModel.fromJson(json);
        } catch (e) {
          debugPrint('DEBUG: [NotificationRepo] Error parsing individual notification: $e. JSON: $json');
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint('DEBUG: [NotificationRepo] Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    debugPrint('DEBUG: [NotificationRepo] Marking notification $id as read');
    await _api.put('notifications/$id/read', body: {});
  }

  Future<void> markAllAsRead(String shareholderId) async {
    debugPrint('DEBUG: [NotificationRepo] Marking all notifications for $shareholderId as read');
    await _api.put('notifications/read-all', body: {'shareholder_id': shareholderId});
  }

  Future<void> deleteAll(String shareholderId) async {
    debugPrint('DEBUG: [NotificationRepo] Deleting all notifications for $shareholderId');
    await _api.delete('notifications/delete-all', body: {'shareholder_id': shareholderId});
  }
}
