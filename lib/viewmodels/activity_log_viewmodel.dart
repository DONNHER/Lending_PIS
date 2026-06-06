import 'package:flutter/material.dart';
import '../models/activity_log_model.dart';
import '../repositories/activity_log_repository.dart';

class ActivityLogViewModel extends ChangeNotifier {
  final ActivityLogRepository _repository;
  final String? initialUserId;

  List<ActivityLogModel> _logs = [];
  bool _isLoading = false;
  bool _isFetching = false;
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

  Future<void> fetchLogs() async {
    if (_isFetching || _isDisposed) return;
    
    _isFetching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = (_currentPage - 1) * _rowsPerPage;

      final fetchedLogs = await _repository.getActivityLogs(
        offset: offset,
        limit: _rowsPerPage,
        dateFilter: _selectedDateFilter,
        startDate: _startDate,
        endDate: _endDate,
        userId: _filteredShareholderId == null ? initialUserId : null,
        shareholderId: _filteredShareholderId,
      );

      final count = await _repository.getActivityLogsCount(
        userId: _filteredShareholderId == null ? initialUserId : null,
        shareholderId: _filteredShareholderId,
        dateFilter: _selectedDateFilter,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      _totalRows = count;
      _logs = fetchedLogs;
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      _errorMessage = e.toString();
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void fetchRequestsByShareholder(String shareholderId) {
    _filteredShareholderId = shareholderId;
    _currentPage = 1;
    fetchLogs();
  }

  void clearShareholderFilter() {
    _filteredShareholderId = null;
    _currentPage = 1;
    fetchLogs();
  }

  void setDateFilter(String filter) {
    _selectedDateFilter = filter;
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    fetchLogs();
  }

  void setDateRange(DateTime start, DateTime end) {
    _selectedDateFilter = 'Custom Range';
    _startDate = start;
    _endDate = end;
    _currentPage = 1;
    fetchLogs();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      fetchLogs();
    }
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    fetchLogs();
  }

  Future<void> deleteLog(String id) async {
    try {
      await _repository.deleteActivityLog(id);
      await fetchLogs();
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }
}
