import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';

class ActivityLogViewModel extends ChangeNotifier {
  final ActivityLogRepository _activityLogRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<dynamic> _logs = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;

  ActivityLogViewModel(this._activityLogRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<dynamic> get logs => _logs;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;

  Future<void> fetchLogs({int? page, int? perPage}) async {
    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      _logs = await _activityLogRepository.getLogs();
      
      _totalRows = _logs.length;
      _lastPage = (_totalRows / _rowsPerPage).ceil();
      if (_lastPage == 0) _lastPage = 1;
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    fetchLogs();
  }

  void setPage(int page) {
    _currentPage = page;
    fetchLogs();
  }

  void refresh() => fetchLogs();
}
