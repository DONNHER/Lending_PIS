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
      return await getNotifications(shareholderId);
    });
  }

  Future<List<NotificationModel>> getNotifications(String shareholderId) async {
    try {
      final response = await _api.get('notifications', queryParams: {'shareholder_id': shareholderId});
      final List<dynamic> data = response['data'];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    await _api.put('notifications/$id/read', body: {});
  }

  Future<void> markAllAsRead(String shareholderId) async {
    await _api.put('notifications/read-all', body: {'shareholder_id': shareholderId});
  }
}
