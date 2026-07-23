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

        // 2. Fetch loan requests based on role
        if (_loanRequestFilter == 'borrower') {
          _loanRequests = await _lendingRepository.getLoanRequestsByShareholderId(shareholderId);
        } else {
          _loanRequests = await _lendingRepository.getLoanRequestsByComakerId(shareholderId);
        }

        // 3. FETCH THE ACTIVE LOAN HERE
        // (Replace `getActiveLoanByShareholderId` with the actual method name in your LendingRepository)
        try {
          _activeLoan = await _lendingRepository.getActiveLoanByShareholderId(shareholderId);
        } catch (_) {
          _activeLoan = null; // Fallback if none exists or endpoint throws 404
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
