import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity_log_model.dart';
import '../repositories/activity_log_repository.dart';
import '../services/local_cache_service.dart';

class ActivityLogViewModel extends ChangeNotifier {
  final ActivityLogRepository _repository;
  final LocalCacheService? _cache;
  final String? initialUserId;

  List<ActivityLogModel> _logs = [];
  bool _isLoading = false;
  bool _isFetching = false;
  bool _isInitialized = false; 
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _selectedDateFilter = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _errorMessage;
  String? _filteredShareholderId;
  bool _isDisposed = false;

  ActivityLogViewModel(this._repository, {this.initialUserId, LocalCacheService? cacheService})
      : _cache = cacheService;

  List<ActivityLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; 
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
    
    if (_isInitialized && !forceRefresh && _logs.isNotEmpty) return;

    final cacheKey = 'admin_activity_logs_p${_currentPage}_f$_selectedDateFilter';

    // 1. Try to load from Cache first
    if (_cache != null && !forceRefresh) {
      final cached = await _cache!.getData(cacheKey);
      if (cached != null && cached is Map) {
        _logs = (cached['data'] as List).map((e) => ActivityLogModel.fromJson(e)).toList();
        _totalRows = cached['total'] ?? 0;
        _isInitialized = true;
        notifyListeners();
      }
    }

    if (!forceRefresh && _isInitialized) {
      _performBackgroundFetch(cacheKey);
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _performBackgroundFetch(cacheKey);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _performBackgroundFetch(String cacheKey) async {
    if (_isDisposed) return;
    _isFetching = true;

    try {
      final offset = (_currentPage - 1) * _rowsPerPage;

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

        // Save to cache
        if (_cache != null) {
          await _cache!.saveData(cacheKey, {
            'data': _logs.map((e) => e.toJson()).toList(),
            'total': _totalRows,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      if (!_isDisposed && !_isInitialized) {
        _errorMessage = e.toString();
      }
    } finally {
      _isFetching = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  Future<void> fetchRequestsByShareholder(String shareholderId) async {
    if (_filteredShareholderId == shareholderId && _isInitialized) return;
    _filteredShareholderId = shareholderId;
    _currentPage = 1;
    await fetchLogs(forceRefresh: true);
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
