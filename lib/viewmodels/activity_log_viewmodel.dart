import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';

class ActivityLogViewModel extends ChangeNotifier {
  final ActivityLogRepository _activityLogRepository;

  bool _isLoading = false;
  bool _isInitialized = false;

  ActivityLogViewModel(this._activityLogRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _activityLogRepository.getLogs();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
