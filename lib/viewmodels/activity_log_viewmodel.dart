import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';

class ActivityLogViewModel extends ChangeNotifier {
  final ActivityLogRepository _activityLogRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<dynamic> _logs = [];
  List<dynamic> _filteredLogs = [];
  
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
  List<dynamic> get logs => _filteredLogs;
  
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
      _logs = await _activityLogRepository.getLogs();
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
    _filteredLogs = List.from(_logs);

    // Filter by Type
    if (_typeFilter != 'All') {
      _filteredLogs = _filteredLogs.where((l) => 
        (l['type'] ?? 'info').toString().toLowerCase() == _typeFilter.toLowerCase()
      ).toList();
    }

    // Sorting
    switch (_sortOrder) {
      case 'Newest':
        _filteredLogs.sort((a, b) => 
          DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
        );
        break;
      case 'Oldest':
        _filteredLogs.sort((a, b) => 
          DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at']))
        );
        break;
    }

    _totalRows = _filteredLogs.length;
    _lastPage = (_totalRows / _rowsPerPage).ceil();
    if (_lastPage == 0) _lastPage = 1;
    
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex < _filteredLogs.length) {
      final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredLogs.length);
      _filteredLogs = _filteredLogs.sublist(startIndex, endIndex);
    } else {
      _filteredLogs = [];
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
