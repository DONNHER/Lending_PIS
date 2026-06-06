import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/shareholder_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository;
  final ShareholderRepository _shareholderRepo;
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _shareholderId; 
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _subscription;
  bool _isLoading = false;
  bool _isInitialized = false; // 🚀 Caching flag

  NotificationViewModel(this._repository, this._shareholderRepo);

  String? get shareholderId => _shareholderId;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> fetchData({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return; // 🚀 Cache hit

    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) {
      _resetState();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final shareholder = await _shareholderRepo.getShareholderByUserId(authId);

      if (shareholder != null) {
        _shareholderId = shareholder.id;
        _initNotificationStream();
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('NotificationVM Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initNotificationStream() {
    if (_shareholderId == null) return;
    _subscription?.cancel();
    _subscription = _repository
        .subscribeToNotifications(shareholderId: _shareholderId!)
        .listen((data) {
      _notifications = data;
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
    } catch (e) {
      debugPrint('NotificationVM Error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_shareholderId == null) return;
    try {
      await _repository.markAllAsRead(_shareholderId!);
    } catch (e) {
      debugPrint('NotificationVM Error: $e');
    }
  }

  void reset() {
    _resetState();
  }

  void _resetState() {
    _subscription?.cancel();
    _notifications = [];
    _shareholderId = null;
    _isLoading = false;
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
