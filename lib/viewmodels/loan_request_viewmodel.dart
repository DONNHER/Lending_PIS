import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';

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
  StreamSubscription? _realtimeSubscription;

  List<LoanRequestModel> _loanRequests = [];
  bool _isLoading = false;
  bool _isInitialized = false; // 🚀 Caching flag
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String? _selectedStatus; 
  String? _filteredShareholderId; 
  LoanRequestSortField _sortField = LoanRequestSortField.createdAt;
  bool _sortAscending = false; 
  String? _errorMessage;

  LoanRequestViewModel(this._repository) {
    debugPrint('[LoanRequestViewModel] Initializing...');
    _startListening();
    // We don't fetch automatically here anymore to allow ProxyProvider control
  }

  List<LoanRequestModel> get loanRequests => _loanRequests;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; // 🚀 Getter
  int get totalRows => _totalRows;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String? get errorMessage => _errorMessage;
  String? get filteredShareholderId => _filteredShareholderId; 

  int get totalPages {
    if (_totalRows <= 0) return 1;
    return (_totalRows / _rowsPerPage).ceil();
  }

  String? get selectedStatus => _selectedStatus;

  String get sortByDateLabel =>
      _sortField == LoanRequestSortField.createdAt
          ? (_sortAscending ? 'Date · Oldest' : 'Date · Newest')
          : 'Date';

  String get sortByAmountLabel =>
      _sortField == LoanRequestSortField.requestedAmount
          ? (_sortAscending ? 'Amount · Low' : 'Amount · High')
          : 'Amount';

  void _startListening() {
    _realtimeSubscription = _repository.getLoanRequestsStream().listen((data) {
      if (_isInitialized) {
        fetchLoanRequests(showLoading: false, forceRefresh: true);
      }
    });
  }

  void fetchRequestsByShareholder(String shareholderId) {
    if (_filteredShareholderId == shareholderId && _isInitialized) return;
    _filteredShareholderId = shareholderId;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void clearShareholderFilter() {
    _filteredShareholderId = null;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  Future<void> fetchLoanRequests({bool showLoading = true, bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return; // 🚀 Cache hit

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final offset = (_currentPage - 1) * _rowsPerPage;
      
      // Concurrent fetching
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
      _isInitialized = true; // 🚀 Mark initialized

      if (_currentPage > totalPages && totalPages > 0) {
        _currentPage = totalPages;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatus(String? status) {
    _selectedStatus = status;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void setSortByDate({required bool oldestFirst}) {
    _sortField = LoanRequestSortField.createdAt;
    _sortAscending = oldestFirst;
    _currentPage = 1;
    fetchLoanRequests(forceRefresh: true);
  }

  void setSortByAmount({required bool lowestFirst}) {
    _sortField = LoanRequestSortField.requestedAmount;
    _sortAscending = lowestFirst;
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

  void reset() {
    _isInitialized = false;
    _loanRequests = [];
    _filteredShareholderId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
