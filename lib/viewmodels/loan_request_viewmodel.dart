import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/models/lending_models.dart';

class LoanRequestViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<LoanRequestModel> _loanRequests = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;
  String? _statusFilter;

  LoanRequestViewModel(this._lendingRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<LoanRequestModel> get loanRequests => _loanRequests;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;

  Future<void> fetchLoanRequests({int? page, int? perPage}) async {
    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      // For now we don't have paginated endpoint in repo for loans, 
      // but we can simulate or update repository later.
      // Let's assume we update repo to support it.
      _loanRequests = await _lendingRepository.getLoanRequests();
      
      // Mock pagination since repo currently returns full list
      _totalRows = _loanRequests.length;
      _lastPage = (_totalRows / _rowsPerPage).ceil();
      if (_lastPage == 0) _lastPage = 1;
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching loan requests: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    fetchLoanRequests();
  }

  void setPage(int page) {
    _currentPage = page;
    fetchLoanRequests();
  }

  void refresh() => fetchLoanRequests();
}
