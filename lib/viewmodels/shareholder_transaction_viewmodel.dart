import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/models/transaction_model.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class ShareholderTransactionViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;
  final ShareholderRepository _shareholderRepository;
  final LendingRepository _lendingRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String _selectedFilter = 'All';
  String _roleFilter = 'Borrower';
  List<TransactionModel> _allTransactions = [];
  List<LoanRequestModel> _allLoanRequests = [];
  ShareholderModel? _currentShareholder;
  String? _lastUserId;

  ShareholderTransactionViewModel(
    this._transactionRepository,
    this._shareholderRepository,
    this._lendingRepository,
  );

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  String get roleFilter => _roleFilter;
  List<LoanRequestModel> get loanRequests => _allLoanRequests;

  List<TransactionModel> get transactions {
    if (_selectedFilter == 'All') return _allTransactions;
    if (_selectedFilter == 'Loans') {
      return _allTransactions.where((t) => t.type.toLowerCase().contains('loan')).toList();
    }
    if (_selectedFilter == 'Repayments') {
      return _allTransactions.where((t) => t.type.toLowerCase().contains('payment') || t.type.toLowerCase().contains('repayment')).toList();
    }
    if (_selectedFilter == 'Capital Contributions') {
      return _allTransactions.where((t) => t.type.toLowerCase().contains('capital')).toList();
    }
    return [];
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setRoleFilter(String role) {
    _roleFilter = role;
    if (_lastUserId != null) {
       fetchData(userId: _lastUserId!, forceRefresh: true);
    } else {
      notifyListeners();
    }
  }

  void setUserId(String id) {
    if (_lastUserId != id) {
      _isInitialized = false;
      fetchData(userId: id);
    }
  }

  Future<void> fetchData({required String userId, bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    _lastUserId = userId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentShareholder == null || forceRefresh) {
        _currentShareholder = await _shareholderRepository.getShareholderByUserId(userId);
      }

      if (_currentShareholder == null) {
        throw Exception("Shareholder profile not found.");
      }

      final shareholderId = _currentShareholder!.id;

      final results = await Future.wait([
        _transactionRepository.getTransactionsByShareholderId(shareholderId),
        _roleFilter == 'Borrower' 
            ? _lendingRepository.getLoanRequestsByShareholderId(shareholderId)
            : _lendingRepository.getLoanRequestsByComakerId(shareholderId),
      ]);

      _allTransactions = results[0] as List<TransactionModel>;
      _allLoanRequests = results[1] as List<LoanRequestModel>;
      
      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _allTransactions = [];
    _allLoanRequests = [];
    _currentShareholder = null;
    _lastUserId = null;
    _isInitialized = false;
    _errorMessage = null;
    _selectedFilter = 'All';
    _roleFilter = 'Borrower';
    notifyListeners();
  }
}
