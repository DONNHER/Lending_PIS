import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../services/local_cache_service.dart';

enum LoanRequestSortField {
  createdAt,
  requestedAmount,
}

extension LoanRequestSortFieldX on LoanRequestSortField {
  String get columnName => switch (this) {
    LoanRequestSortField.createdAt => 'created_at',
    LoanRequestSortField.requestedAmount => 'requested_amount',
  };
}

class LoanRequestViewModel extends ChangeNotifier {
  final LendingRepository _repository;
  final LocalCacheService? _cache;
  StreamSubscription? _realtimeSubscription;

  List<LoanRequestModel> _loanRequests = [];
  bool _isLoading = false;
  bool _isInitialized = false; 
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String? _selectedStatus; 
  String? _filteredShareholderId; 
  String? _filteredShareholderName;
  LoanRequestSortField _sortField = LoanRequestSortField.createdAt;
  bool _sortAscending = false; 
  String? _errorMessage;

  LoanRequestViewModel(this._repository, {LocalCacheService? cacheService}) 
      : _cache = cacheService {
    _startListening();
  }

  List<LoanRequestModel> get loanRequests => _loanRequests;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; 
  int get totalRows => _totalRows;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String? get errorMessage => _errorMessage;
  String? get filteredShareholderId => _filteredShareholderId; 
  String? get filteredShareholderName => _filteredShareholderName;

  int get totalPages {
    if (_totalRows <= 0) return 1;
    return (_totalRows / _rowsPerPage).ceil();
  }

  String? get selectedStatus => _selectedStatus;

  String get sortByAmountLabel {
    if (_sortField != LoanRequestSortField.requestedAmount) return 'Sort by Amount';
    return _sortAscending ? 'Amount (Low to High)' : 'Amount (High to Low)';
  }

  String get sortByDateLabel {
    if (_sortField != LoanRequestSortField.createdAt) return 'Sort by Date';
    return _sortAscending ? 'Date (Oldest First)' : 'Date (Newest First)';
  }

  void _startListening() {
    _realtimeSubscription = _repository.getLoanRequestsStream().listen((data) {
      if (_isInitialized) {
        fetchLoanRequests(showLoading: false, forceRefresh: true);
      }
    });
  }

  Future<void> fetchLoanRequests({bool showLoading = true, bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return;

    final cacheKey = 'admin_loan_requests_p${_currentPage}_s${_selectedStatus ?? "all"}';

    // 1. Try to load from Cache first
    if (_cache != null && !forceRefresh) {
      final cached = await _cache!.getData(cacheKey);
      if (cached != null && cached is Map) {
        _loanRequests = (cached['data'] as List).map((e) => LoanRequestModel.fromJson(e)).toList();
        _totalRows = cached['total'] ?? 0;
        _isInitialized = true;
        notifyListeners();
      }
    }

    if (!forceRefresh && _isInitialized) {
      // Trigger background sync
      _performBackgroundFetch(cacheKey);
      return;
    }

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    await _performBackgroundFetch(cacheKey);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _performBackgroundFetch(String cacheKey) async {
    try {
      final offset = (_currentPage - 1) * _rowsPerPage;
      
      final results = await Future.wait([
        _repository.getLoanRequests(
          offset: offset >= 0 ? offset : 0,
          limit: _rowsPerPage,
          status: _selectedStatus,
          shareholderId: _filteredShareholderId,
          orderColumn: _sortField.columnName,
          ascending: _sortAscending,
        ),
        _repository.getLoanRequestsCount(
          status: _selectedStatus,
          shareholderId: _filteredShareholderId,
        ),
      ]);

      _loanRequests = results[0] as List<LoanRequestModel>;
      _totalRows = results[1] as int;
      _isInitialized = true;

      // Save to cache
      if (_cache != null) {
        await _cache!.saveData(cacheKey, {
          'data': _loanRequests.map((e) => e.toJson()).toList(),
          'total': _totalRows,
        });
      }
    } catch (e) {
      debugPrint('LoanRequestVM Error: $e');
      if (!_isInitialized) {
        _errorMessage = e.toString();
      }
    } finally {
      notifyListeners();
    }
  }

  void setShareholderFilter(String id, String name) {
    _filteredShareholderId = id;
    _filteredShareholderName = name;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void setStatus(String? status) {
    _selectedStatus = status;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      fetchLoanRequests(forceRefresh: true);
    }
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void clearShareholderFilter() {
    _filteredShareholderId = null;
    _filteredShareholderName = null;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void setSortByAmount({required bool lowestFirst}) {
    _sortField = LoanRequestSortField.requestedAmount;
    _sortAscending = lowestFirst;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void setSortByDate({required bool oldestFirst}) {
    _sortField = LoanRequestSortField.createdAt;
    _sortAscending = oldestFirst;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void reset() {
    _isInitialized = false;
    _loanRequests = [];
    _filteredShareholderId = null;
    _filteredShareholderName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
