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

  Future<void> loadNotifications({required String shareholderId, bool forceRefresh = false}) async {
    _isLoading = true;
    _shareholderId = shareholderId;
    notifyListeners();

    try {
      final List<NotificationModel> result = await _notificationRepository.getNotifications(shareholderId);
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
      // 1. Instantly update the local list item using copyWith
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isUnread: false);
        notifyListeners(); // UI updates instantly!
      }

      // 2. Persist change on the backend
      await _notificationRepository.markAsRead(id);
    } catch (e) {
      debugPrint('Error marking as read: $e');
      // Re-fetch if it failed to stay in sync
      if (_shareholderId != null) {
        await loadNotifications(shareholderId: _shareholderId!, forceRefresh: true);
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (_shareholderId == null) return;
    try {
      // Optimistic local update
      _notifications = _notifications.map((n) => n.copyWith(isUnread: false)).toList();
      notifyListeners();

      await _notificationRepository.markAllAsRead(_shareholderId!);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      if (_shareholderId != null) {
        await loadNotifications(shareholderId: _shareholderId!, forceRefresh: true);
      }
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