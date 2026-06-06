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

  int _totalRows = 0;

  int _currentPage = 1;

  int _rowsPerPage = 10;

  String? _selectedStatus; // null = show all loan requests

  String? _filteredShareholderId; // ✨ Added dynamic single-shareholder filter target

  LoanRequestSortField _sortField = LoanRequestSortField.createdAt;

  bool _sortAscending = false; // created_at: false = newest first; amount: false = highest first

  String? _errorMessage;



  LoanRequestViewModel(this._repository) {

    debugPrint('[LoanRequestViewModel] Initializing...');

    _startListening();

    fetchLoanRequests();

  }



  List<LoanRequestModel> get loanRequests => _loanRequests;

  bool get isLoading => _isLoading;

  int get totalRows => _totalRows;

  int get currentPage => _currentPage;

  int get rowsPerPage => _rowsPerPage;

  String? get errorMessage => _errorMessage;

  String? get filteredShareholderId => _filteredShareholderId; // ✨ Getter for checking state



  int get totalPages {

    if (_totalRows <= 0) return 1;

    return (_totalRows / _rowsPerPage).ceil();

  }



  String? get selectedStatus => _selectedStatus;



  /// Label for the Date filter control (shows active sort when sorting by date).

  String get sortByDateLabel =>

      _sortField == LoanRequestSortField.createdAt

          ? (_sortAscending ? 'Date · Oldest' : 'Date · Newest')

          : 'Date';



  /// Label for the Amount filter control (shows active sort when sorting by amount).

  String get sortByAmountLabel =>

      _sortField == LoanRequestSortField.requestedAmount

          ? (_sortAscending ? 'Amount · Low' : 'Amount · High')

          : 'Amount';



  void _startListening() {

    debugPrint('[LoanRequestViewModel] Starting Supabase real-time subscription...');

    _realtimeSubscription = _repository.getLoanRequestsStream().listen((data) {

      debugPrint('[LoanRequestViewModel] Real-time update detected in loan_requests table');

      fetchLoanRequests(showLoading: false);

    }, onError: (error) {

      debugPrint('[LoanRequestViewModel] Real-time subscription error: $error');

    });

  }



  /// ✨ Registers a dedicated shareholder context filter and re-triggers fetch.

  void fetchRequestsByShareholder(String shareholderId) {

    debugPrint('[LoanRequestViewModel] Target filter configured for shareholderId: $shareholderId');

    _filteredShareholderId = shareholderId;

    _currentPage = 1;

    fetchLoanRequests();

  }



  /// ✨ Clears out the target shareholder context filter back to standard system views.

  void clearShareholderFilter() {

    debugPrint('[LoanRequestViewModel] Clearing shareholder filter.');

    _filteredShareholderId = null;

    _currentPage = 1;

    fetchLoanRequests();

  }



  Future<void> fetchLoanRequests({bool showLoading = true}) async {

    debugPrint('[LoanRequestViewModel] fetchLoanRequests started. Status: $_selectedStatus, Shareholder Filter: $_filteredShareholderId, Page: $_currentPage');

    if (showLoading) {

      _isLoading = true;

      _errorMessage = null;

      notifyListeners();

    }



    try {

      final offset = (_currentPage - 1) * _rowsPerPage;

      debugPrint('[LoanRequestViewModel] Calling repository: offset=$offset, limit=$_rowsPerPage');



// ✨ Added shareholderId mapping parameter to repository data layer call

      _loanRequests = await _repository.getLoanRequests(

        offset: offset >= 0 ? offset : 0,

        limit: _rowsPerPage,

        status: _selectedStatus,

        shareholderId: _filteredShareholderId, // Pass the filtered ID down

        orderColumn: _sortField.columnName,

        ascending: _sortAscending,

      );



// ✨ Added shareholderId mapping parameter to repository calculation count layer call

      _totalRows = await _repository.getLoanRequestsCount(

        status: _selectedStatus,

        shareholderId: _filteredShareholderId, // Count metrics must respect filter bounds

      );



      debugPrint('[LoanRequestViewModel] Successfully fetched ${_loanRequests.length} requests');



      if (_currentPage > totalPages && totalPages > 0) {

        _currentPage = totalPages;

      }

    } catch (e, stack) {

      _errorMessage = e.toString();

      debugPrint('[LoanRequestViewModel] Error: $e');

      debugPrint(stack.toString());

    } finally {

      _isLoading = false;

      notifyListeners();

    }

  }



  void setStatus(String? status) {

    _selectedStatus = status;

    _currentPage = 1;

    fetchLoanRequests();

  }



  void setSortByDate({required bool oldestFirst}) {

    _sortField = LoanRequestSortField.createdAt;

    _sortAscending = oldestFirst;

    _currentPage = 1;

    fetchLoanRequests();

  }



  void setSortByAmount({required bool lowestFirst}) {

    _sortField = LoanRequestSortField.requestedAmount;

    _sortAscending = lowestFirst;

    _currentPage = 1;

    fetchLoanRequests();

  }



  void setPage(int page) {

    if (page >= 1 && page <= totalPages) {

      _currentPage = page;

      fetchLoanRequests();

    }

  }



  void setRowsPerPage(int rows) {

    _rowsPerPage = rows;

    _currentPage = 1;

    fetchLoanRequests();

  }



  // Future<void> deleteRequest(String id) async {
  //
  //   try {
  //
  //     await _repository.deleteLoanRequest(id);
  //
  //   } catch (e) {
  //
  //     debugPrint('[LoanRequestViewModel] Delete error: $e');
  //
  //   }
  //
  // }



  @override

  void dispose() {

    _realtimeSubscription?.cancel();

    super.dispose();

  }

}