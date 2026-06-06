import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lending_models.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/shareholder_repository.dart';

class ShareholderTransactionViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepo;
  final ShareholderRepository _shareholderRepo;

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = false;
  bool _isInitialized = false; // 🚀 Caching flag
  String _selectedFilter = 'All';
  String? _errorMessage;

  ShareholderTransactionViewModel(this._transactionRepo, this._shareholderRepo);

  List<TransactionModel> get transactions => _filteredTransactions;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; // 🚀 Getter
  String get selectedFilter => _selectedFilter;
  String? get errorMessage => _errorMessage;

  Future<void> fetchData({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return; // 🚀 Cache hit

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Get Shareholder Profile
      final shareholder = await _shareholderRepo.getShareholderByUserId(user.id);
      if (shareholder == null) {
        _errorMessage = "Shareholder profile not found.";
        _isLoading = false;
        _isInitialized = true; // Mark as attempted
        notifyListeners();
        return;
      }

      // 2. Fetch all transactions for this shareholder
      _allTransactions = await _transactionRepo.getTransactionsByShareholderId(shareholder.id);
      _isInitialized = true;
      _applyFilter();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[ShareholderTransactionViewModel] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredTransactions = _allTransactions;
    } else if (_selectedFilter == 'Loans') {
      _filteredTransactions = _allTransactions
          .where((tx) => tx.type.toLowerCase().contains('loan disbursement') || tx.type.toLowerCase() == 'loan')
          .toList();
    } else if (_selectedFilter == 'Repayments') {
      _filteredTransactions = _allTransactions
          .where((tx) => tx.type.toLowerCase().contains('payment') || tx.type.toLowerCase().contains('repayment'))
          .toList();
    } else if (_selectedFilter == 'Capital Contributions') {
      _filteredTransactions = _allTransactions
          .where((tx) => tx.type.toLowerCase().contains('capital'))
          .toList();
    }
  }

  void reset() {
    _isInitialized = false;
    _allTransactions = [];
    _filteredTransactions = [];
    _selectedFilter = 'All';
    notifyListeners();
  }
}
