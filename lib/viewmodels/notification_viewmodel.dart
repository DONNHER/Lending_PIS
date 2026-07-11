import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/notification_repository.dart';
import 'package:capstone_application/models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _notificationRepository;

  List<NotificationModel> _notifications = [];
  String? _shareholderId;
  bool _isLoading = false;

  NotificationViewModel(this._notificationRepository);

  List<NotificationModel> get notifications => _notifications;
  String? get shareholderId => _shareholderId;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> loadNotifications({required String userId, bool forceRefresh = false}) async {
    _isLoading = true;
    _shareholderId = userId;
    notifyListeners();

    try {
      final List<NotificationModel> result = await _notificationRepository.getNotifications(userId);
      _notifications = result;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _notificationRepository.markAsRead(id);
      if (_shareholderId != null) {
        await loadNotifications(userId: _shareholderId!, forceRefresh: true);
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_shareholderId == null) return;
    try {
      await _notificationRepository.markAllAsRead(_shareholderId!);
      await loadNotifications(userId: _shareholderId!, forceRefresh: true);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    if (_shareholderId == null) return;
    try {
      await _notificationRepository.deleteAll(_shareholderId!);
      _notifications = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notifications: $e');
    }
  }

  void reset() {
    _notifications = [];
    _shareholderId = null;
    _isLoading = false;
    notifyListeners();
  }
}
