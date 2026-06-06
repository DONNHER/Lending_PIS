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

  String? _shareholderId; // The Primary Key (PK) from the Shareholders table
  List<NotificationModel> _notifications = [];
  StreamSubscription<List<NotificationModel>>? _subscription;
  bool _isLoading = false;

  NotificationViewModel(this._repository, this._shareholderRepo);

  // ─── Getters ───────────────────────────────────────────────────────────
  String? get shareholderId => _shareholderId;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  /// Triggered when the user logs in.
  /// Uses Supabase Auth UUID to resolve the internal Shareholder PK.
  Future<void> fetchData() async {
    final authId = _supabase.auth.currentUser?.id;

    if (authId == null) {
      debugPrint('NotificationVM: No Auth Session. Clearing state.');
      _resetState();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('NotificationVM: Resolving Shareholder PK for Auth ID: $authId');

      // Step 1: Bridge the Auth UUID to the Shareholder record
      final shareholder = await _shareholderRepo.getShareholderByUserId(authId);

      if (shareholder != null) {
        _shareholderId = shareholder.id;
        debugPrint('NotificationVM: Successfully resolved PK: $_shareholderId');

        // Step 2: Initialize real-time stream using the Shareholder PK
        _initNotificationStream();
      } else {
        debugPrint('NotificationVM: No shareholder record found in DB.');
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('NotificationVM ERROR during setup: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets up a real-time listener using the Shareholder ID (PK).
  void _initNotificationStream() {
    if (_shareholderId == null) return;

    _subscription?.cancel();

    // The repository handles the logic of checking borrower OR comaker
    _subscription = _repository
        .subscribeToNotifications(shareholderId: _shareholderId!)
        .listen((data) {
      _notifications = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('NotificationVM Stream Error: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  // ─── Actions ──────────────────────────────────────────────────────────
  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      // Local state update isn't strictly necessary as the stream will emit changes,
      // but you can manually toggle it here if you want instant UI feedback.
    } catch (e) {
      debugPrint('NotificationVM Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_shareholderId == null) return;
    try {
      // Corrected: Uses Shareholder PK to mark everything in DB
      await _repository.markAllAsRead(_shareholderId!);
    } catch (e) {
      debugPrint('NotificationVM Error marking all as read: $e');
    }
  }

  void _resetState() {
    _subscription?.cancel();
    _notifications = [];
    _shareholderId = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}