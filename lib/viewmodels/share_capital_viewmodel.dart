import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class ShareCapitalViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepository;
  final LendingRepository _lendingRepository;

  String? _userId;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String _shareholderFirstName = '';
  double _totalCapital = 0.0;
  LoanModel? _activeLoan;
  List<LoanRequestModel> _loanRequests = [];
  String _loanRequestFilter = 'borrower';
  ShareholderModel? _currentShareholder;

  ShareCapitalViewModel(
    this._shareholderRepository,
    TransactionRepository transactionRepository,
    this._lendingRepository,
  );

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String get shareholderFirstName => _shareholderFirstName;
  double get totalCapital => _totalCapital;
  LoanModel? get activeLoan => _activeLoan;
  List<LoanRequestModel> get loanRequests => _loanRequests;
  String get loanRequestFilter => _loanRequestFilter;
  ShareholderModel? get currentShareholder => _currentShareholder;

  void setUserId(String id) {
    if (_userId != id) {
      _userId = id;
      _isInitialized = false;
      _currentShareholder = null;
      fetchData();
    }
  }

  Future<void> fetchData({bool forceRefresh = false}) async {
    if (_userId == null) return;
    if (_isInitialized && !forceRefresh && !_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Resolve Shareholder Profile
      if (_currentShareholder == null || forceRefresh) {
        _currentShareholder = await _shareholderRepository.getShareholderByUserId(_userId!);
      }

      if (_currentShareholder != null) {
        _shareholderFirstName = _currentShareholder!.firstName;
        _totalCapital = _currentShareholder!.shareCapital;

        final shareholderId = _currentShareholder!.id;

        // 2. Fetch loan requests
        _loanRequests = await _lendingRepository.getLoanRequestsByShareholderId(shareholderId);

        // 3. FIND ACTIVE LOAN USING EXISTING REPOSITORY METHODS
        _activeLoan = null;
        for (var request in _loanRequests) {
          // Check if the request is approved or released/disbursed
          final status = request.status.name.toLowerCase();
          if (status == 'approved' || status == 'released' || status == 'active') {
            try {
              // Use the existing repository method that matches your backend
              final loan = await _lendingRepository.getLoanByLoanRequestId(request.id);
              if (loan != null && loan.remainingBalance > 0) {
                _activeLoan = loan;
                break; // Found the active loan, stop searching
              }
            } catch (_) {
              // Ignore if individual loan lookup fails, continue checking others
            }
          }
        }

      } else {
        throw Exception("Shareholder profile not found.");
      }

      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoanRequestFilter(String filter) {
    if (_loanRequestFilter != filter) {
      _loanRequestFilter = filter;
      fetchData(forceRefresh: true);
    }
  }

  void reset() {
    _userId = null;
    _isInitialized = false;
    _shareholderFirstName = '';
    _totalCapital = 0.0;
    _activeLoan = null;
    _loanRequests = [];
    _currentShareholder = null;
    notifyListeners();
  }
}
