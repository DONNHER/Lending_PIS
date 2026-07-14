import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/models/lending_models.dart';

class LoanRequestViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<LoanRequestModel> _loanRequests = [];
  List<LoanRequestModel> _filteredRequests = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;

  // Filtering
  String _statusFilter = 'All';
  String _purposeFilter = 'All';
  String _sortOrder = 'Newest';

  LoanRequestViewModel(this._lendingRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<LoanRequestModel> get loanRequests => _filteredRequests;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;
  
  String get statusFilter => _statusFilter;
  String get purposeFilter => _purposeFilter;
  String get sortOrder => _sortOrder;

  Future<void> fetchLoanRequests({int? page, int? perPage, bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_isInitialized && !forceRefresh && page == null && perPage == null) return;

    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      _loanRequests = await _lendingRepository.getLoanRequests();
      _applyFilters();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching loan requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredRequests = List.from(_loanRequests);

    // Filter by Status
    if (_statusFilter != 'All') {
      final normalizedFilter = _statusFilter.toLowerCase().replaceAll(' ', '');
      _filteredRequests = _filteredRequests.where((r) {
        final statusName = r.status.name.toLowerCase();
        return statusName == normalizedFilter;
      }).toList();
    }

    // Filter by Purpose
    if (_purposeFilter != 'All') {
      _filteredRequests = _filteredRequests.where((r) => 
        r.purpose.toLowerCase() == _purposeFilter.toLowerCase()
      ).toList();
    }

    // Sorting
    switch (_sortOrder) {
      case 'Newest':
        _filteredRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        _filteredRequests.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Highest Amount':
        _filteredRequests.sort((a, b) => b.requestedAmount.compareTo(a.requestedAmount));
        break;
      case 'Lowest Amount':
        _filteredRequests.sort((a, b) => a.requestedAmount.compareTo(b.requestedAmount));
        break;
    }

    _totalRows = _filteredRequests.length;
    _lastPage = (_totalRows / _rowsPerPage).ceil();
    if (_lastPage == 0) _lastPage = 1;
    
    // Manual pagination since repo doesn't support it yet
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex < _filteredRequests.length) {
      final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredRequests.length);
      _filteredRequests = _filteredRequests.sublist(startIndex, endIndex);
    } else {
      _filteredRequests = [];
    }
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _currentPage = 1;
    _applyFilters();
    notifyListeners();
  }

  void setPurposeFilter(String purpose) {
    _purposeFilter = purpose;
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

  void refresh() => fetchLoanRequests(forceRefresh: true);
}
