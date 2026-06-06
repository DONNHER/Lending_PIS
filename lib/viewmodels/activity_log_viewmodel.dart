import 'package:flutter/material.dart';
import '../models/activity_log_model.dart';
import '../repositories/activity_log_repository.dart';

class ActivityLogViewModel extends ChangeNotifier {
  final ActivityLogRepository _repository;
  final String? initialUserId;

  List<ActivityLogModel> _logs = [];
  bool _isLoading = false;
  bool _isFetching = false;
  bool _isInitialized = false; // 🚀 Caching flag
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _selectedDateFilter = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _errorMessage;
  String? _filteredShareholderId;
  bool _isDisposed = false;

  ActivityLogViewModel(this._repository, {this.initialUserId});

  List<ActivityLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; // 🚀 Getter
  int get totalRows => _totalRows;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String get selectedDateFilter => _selectedDateFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get errorMessage => _errorMessage;
  String? get filteredShareholderId => _filteredShareholderId;

  int get totalPages => (_totalRows / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> fetchLogs({bool forceRefresh = false}) async {
    if (_isFetching || _isDisposed) return;
    
    // 🚀 Avoid redundant loading unless forced
    if (_isInitialized && !forceRefresh && _logs.isNotEmpty) return;

    _isFetching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = (_currentPage - 1) * _rowsPerPage;

      // Concurrent fetching for better performance
      final results = await Future.wait([
        _repository.getActivityLogs(
          offset: offset,
          limit: _rowsPerPage,
          dateFilter: _selectedDateFilter,
          startDate: _startDate,
          endDate: _endDate,
          userId: _filteredShareholderId == null ? initialUserId : null,
          shareholderId: _filteredShareholderId,
        ),
        _repository.getActivityLogsCount(
          userId: _filteredShareholderId == null ? initialUserId : null,
          shareholderId: _filteredShareholderId,
          dateFilter: _selectedDateFilter,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ]);

      if (!_isDisposed) {
        _logs = results[0] as List<ActivityLogModel>;
        _totalRows = results[1] as int;
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      if (!_isDisposed) {
        _errorMessage = e.toString();
      }
    } finally {
      _isFetching = false;
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  void fetchRequestsByShareholder(String shareholderId) {
    if (_filteredShareholderId == shareholderId && _isInitialized) return;
    _filteredShareholderId = shareholderId;
    _currentPage = 1;
    fetchLogs(forceRefresh: true);
  }

  void clearShareholderFilter() {
    _filteredShareholderId = null;
    _currentPage = 1;
    fetchLogs(forceRefresh: true);
  }

  void setDateFilter(String filter) {
    _selectedDateFilter = filter;
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    fetchLogs(forceRefresh: true);
  }

  void setDateRange(DateTime start, DateTime end) {
    _selectedDateFilter = 'Custom Range';
    _startDate = start;
    _endDate = end;
    _currentPage = 1;
    fetchLogs(forceRefresh: true);
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      fetchLogs(forceRefresh: true);
    }
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    fetchLogs(forceRefresh: true);
  }

  Future<void> deleteLog(String id) async {
    try {
      await _repository.deleteActivityLog(id);
      await fetchLogs(forceRefresh: true);
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  void reset() {
    _isInitialized = false;
    _logs = [];
    _currentPage = 1;
    _totalRows = 0;
    notifyListeners();
  }
}
