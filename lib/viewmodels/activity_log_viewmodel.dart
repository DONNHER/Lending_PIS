import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';
import 'package:capstone_application/models/activity_log_model.dart';

class ActivityLogViewModel extends ChangeNotifier {
  final ActivityLogRepository _activityLogRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<ActivityLog> _allLogs = [];
  List<ActivityLog> _displayLogs = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;

  // Filtering
  String _typeFilter = 'All';
  String _sortOrder = 'Newest';

  ActivityLogViewModel(this._activityLogRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<ActivityLog> get logs => _displayLogs;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;
  String get typeFilter => _typeFilter;
  String get sortOrder => _sortOrder;

  Future<void> fetchLogs({int? page, int? perPage, bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_isInitialized && !forceRefresh && page == null && perPage == null) return;

    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      _allLogs = await _activityLogRepository.getLogs();
      _applyFilters();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    List<ActivityLog> filtered = List.from(_allLogs);

    // Filter by Type
    if (_typeFilter != 'All') {
      filtered = filtered.where((l) => 
        l.type.toLowerCase() == _typeFilter.toLowerCase()
      ).toList();
    }

    // Sorting
    switch (_sortOrder) {
      case 'Newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    _totalRows = filtered.length;
    _lastPage = (_totalRows / _rowsPerPage).ceil();
    if (_lastPage == 0) _lastPage = 1;
    
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex < filtered.length) {
      final endIndex = (startIndex + _rowsPerPage).clamp(0, filtered.length);
      _displayLogs = filtered.sublist(startIndex, endIndex);
    } else {
      _displayLogs = [];
    }
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    _currentPage = 1;
    _applyFilters();
    notifyListeners();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    _applyFilters();
    notifyListeners();
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    _applyFilters();
    notifyListeners();
  }

  void setPage(int page) {
    _currentPage = page;
    _applyFilters();
    notifyListeners();
  }

  void refresh() => fetchLogs(forceRefresh: true);
}
