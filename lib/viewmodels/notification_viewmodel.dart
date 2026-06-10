import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../services/local_cache_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository;
  final ShareholderRepository _shareholderRepo;
  final LocalCacheService? _cache;

  String? _shareholderId; 
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _subscription;
  bool _isLoading = false;
  bool _isInitialized = false; 

  NotificationViewModel(this._repository, this._shareholderRepo, {LocalCacheService? cacheService}) 
      : _cache = cacheService;

  String? get shareholderId => _shareholderId;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> fetchData({String? userId, bool forceRefresh = false}) async {
    debugPrint('DEBUG: [NotificationVM] fetchData called with userId: $userId, forceRefresh: $forceRefresh');
    
    final idToUse = userId ?? _shareholderId; 
    
    if (idToUse == null) {
      debugPrint('DEBUG: [NotificationVM] No userId provided AND no shareholderId stored. Aborting.');
      return;
    }

    if (_isInitialized && !forceRefresh && _notifications.isNotEmpty) {
      debugPrint('DEBUG: [NotificationVM] Already initialized and not forcing refresh.');
      return;
    }

    // 1. Load from Cache first
    if (_cache != null && !forceRefresh && !_isInitialized) {
      final cachedData = await _cache!.getData('notifications_$idToUse');
      if (cachedData != null && cachedData is List) {
        debugPrint('DEBUG: [NotificationVM] Loading ${cachedData.length} notifications from cache');
        _notifications = cachedData.map((json) => NotificationModel.fromJson(json)).toList();
        // We still need to resolve the shareholder ID if it's not set
        if (_shareholderId == null) {
           _performBackgroundFetch(idToUse);
        } else {
           _isInitialized = true;
           notifyListeners();
        }
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('DEBUG: [NotificationVM] Resolving shareholder for ID: $idToUse');
      
      // Try to resolve shareholder ID from User ID
      final shareholder = await _shareholderRepo.getShareholderByUserId(idToUse);
      
      String targetId;
      if (shareholder != null) {
        targetId = shareholder.id;
        debugPrint('DEBUG: [NotificationVM] Resolved shareholderId: $targetId from userId: $idToUse');
      } else {
        // Fallback: Assume idToUse is the shareholderId or try fetching notifications with it directly
        debugPrint('DEBUG: [NotificationVM] Could not find shareholder record for ID: $idToUse. Using as targetId.');
        targetId = idToUse;
      }

      _shareholderId = targetId;
      final data = await _repository.getNotifications(_shareholderId!);
      debugPrint('DEBUG: [NotificationVM] Fetched ${data.length} notifications from API');
      _notifications = data;
      
      if (_cache != null) {
        await _cache!.saveData('notifications_$idToUse', _notifications.map((e) => e.toJson()).toList());
      }

      _initNotificationStream();
      _isInitialized = true;
    } catch (e) {
      debugPrint('DEBUG: [NotificationVM] Error in fetchData: $e');
      // If we failed but have an ID, set it anyway to avoid "Could not resolve" UI if it's just a network error
      if (_shareholderId == null) _shareholderId = idToUse;
    } finally {
      _isLoading = false;
      debugPrint('DEBUG: [NotificationVM] fetchData finished. Notification count: ${_notifications.length}, shareholderId: $_shareholderId');
      notifyListeners();
    }
  }

  void _performBackgroundFetch(String userId) async {
    try {
      debugPrint('DEBUG: [NotificationVM] Starting background fetch for $userId');
      final shareholder = await _shareholderRepo.getShareholderByUserId(userId);
      String targetId = shareholder?.id ?? userId;
      
      _shareholderId = targetId;
      final data = await _repository.getNotifications(targetId);
      debugPrint('DEBUG: [NotificationVM] Background fetch got ${data.length} notifications');
      _notifications = data;
      
      if (_cache != null) {
        await _cache!.saveData('notifications_$userId', _notifications.map((e) => e.toJson()).toList());
      }
      
      _initNotificationStream();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('DEBUG: [NotificationVM] Background Fetch Error: $e');
    }
  }

  void _initNotificationStream() {
    if (_shareholderId == null) {
      debugPrint('DEBUG: [NotificationVM] Cannot init stream: shareholderId is null');
      return;
    }
    _subscription?.cancel();
    
    debugPrint('DEBUG: [NotificationVM] Initializing polling stream for $_shareholderId');
    _subscription = _repository
        .subscribeToNotifications(shareholderId: _shareholderId!)
        .listen((data) {
      debugPrint('DEBUG: [NotificationVM] Stream update: ${data.length} notifications received');
      _notifications = data;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String id) async {
    debugPrint('DEBUG: [NotificationVM] markAsRead called for $id');
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isUnread: false);
        notifyListeners();
      }
      await _repository.markAsRead(id);
    } catch (e) {
      debugPrint('DEBUG: [NotificationVM] MarkRead Error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    debugPrint('DEBUG: [NotificationVM] markAllAsRead called');
    if (_shareholderId == null) return;
    try {
      _notifications = _notifications.map((n) => n.copyWith(isUnread: false)).toList();
      notifyListeners();
      await _repository.markAllAsRead(_shareholderId!);
    } catch (e) {
      debugPrint('DEBUG: [NotificationVM] MarkAllRead Error: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    debugPrint('DEBUG: [NotificationVM] deleteAllNotifications called');
    if (_shareholderId == null) return;
    try {
      _notifications = [];
      notifyListeners();
      
      await _repository.deleteAll(_shareholderId!);
      
      // Update cache
      if (_cache != null) {
        await _cache!.saveData('notifications_$_shareholderId', []);
      }
    } catch (e) {
      debugPrint('DEBUG: [NotificationVM] DeleteAll Error: $e');
      fetchData(forceRefresh: true);
    }
  }

  void reset() {
    debugPrint('DEBUG: [NotificationVM] reset called');
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
    debugPrint('DEBUG: [NotificationVM] dispose called');
    _subscription?.cancel();
    super.dispose();
  }
}
