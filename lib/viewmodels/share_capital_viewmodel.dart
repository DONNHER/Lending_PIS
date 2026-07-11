import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/services/local_cache_service.dart';
import 'package:capstone_application/models/lending_models.dart';

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

  ShareCapitalViewModel(
    this._shareholderRepository,
    TransactionRepository transactionRepository,
    this._lendingRepository, {
    required LocalCacheService cacheService,
  });

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String get shareholderFirstName => _shareholderFirstName;
  double get totalCapital => _totalCapital;
  LoanModel? get activeLoan => _activeLoan;
  List<LoanRequestModel> get loanRequests => _loanRequests;
  String get loanRequestFilter => _loanRequestFilter;

  void setUserId(String id) {
    _userId = id;
    _isInitialized = false;
    notifyListeners();
  }

  Future<void> fetchData({bool forceRefresh = false}) async {
    if (_userId == null) return;
    if (_isInitialized && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final shareholder = await _shareholderRepository.getShareholderById(_userId!);
      if (shareholder != null) {
        _shareholderFirstName = shareholder.firstName;
        _totalCapital = shareholder.shareCapital;
      }

      // Fetch active loan
      final requests = await _lendingRepository.getLoanRequests();
      _loanRequests = requests.where((r) => r.shareholderId == _userId).toList();

      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setLoanRequestFilter(String filter) {
    _loanRequestFilter = filter;
    fetchData(forceRefresh: true);
  }

  void reset() {
    _userId = null;
    _isInitialized = false;
    _shareholderFirstName = '';
    _totalCapital = 0.0;
    _activeLoan = null;
    _loanRequests = [];
    notifyListeners();
  }
}
