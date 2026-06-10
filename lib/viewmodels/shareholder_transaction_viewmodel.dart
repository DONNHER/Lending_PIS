import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../services/local_cache_service.dart';

class ShareholderTransactionViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepo;
  final ShareholderRepository _shareholderRepo;
  final LocalCacheService? _cache;

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = false;
  bool _isInitialized = false; 
  String _selectedFilter = 'All';
  String? _errorMessage;
  String? _userId;

  ShareholderTransactionViewModel(this._transactionRepo, this._shareholderRepo, {LocalCacheService? cacheService})
      : _cache = cacheService;

  List<TransactionModel> get transactions => _filteredTransactions;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; 
  String get selectedFilter => _selectedFilter;
  String? get errorMessage => _errorMessage;

  void setUserId(String? id) {
    if (_userId == id) return;
    _userId = id;
    if (_userId != null) {
      _isInitialized = false;
      fetchData(userId: _userId);
    } else {
      reset();
    }
  }

  Future<void> fetchData({String? userId, bool forceRefresh = false}) async {
    final idToUse = userId ?? _userId;
    if (idToUse == null) return;

    if (_isInitialized && !forceRefresh) return;

    // 1. Load from Cache first
    if (_cache != null) {
      final cachedTxs = await _cache!.getData('shareholder_all_txs_$idToUse');
      if (cachedTxs != null && cachedTxs is List) {
        _allTransactions = cachedTxs.map((e) => TransactionModel.fromJson(e)).toList();
        _isInitialized = true;
        _applyFilter();
        notifyListeners();
      }
    }

    if (!forceRefresh && _isInitialized) {
      // Trigger background update if we have cached data
      _performBackgroundFetch(idToUse);
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _performBackgroundFetch(idToUse);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _performBackgroundFetch(String userId) async {
    try {
      // 1. Get Shareholder Profile
      final shareholder = await _shareholderRepo.getShareholderByUserId(userId);
      if (shareholder == null) {
        _errorMessage = "Shareholder profile not found.";
        _isInitialized = true;
        return;
      }

      // 2. Fetch all transactions for this shareholder
      final data = await _transactionRepo.getTransactionsByShareholderId(shareholder.id);
      _allTransactions = data;
      
      // Update Cache
      if (_cache != null) {
        await _cache!.saveData('shareholder_all_txs_$userId', _allTransactions.map((e) => e.toJson()).toList());
      }

      _isInitialized = true;
      _applyFilter();
    } catch (e) {
      debugPrint('[ShareholderTransactionViewModel] Error: $e');
      if (!_isInitialized) {
        _errorMessage = e.toString();
      }
    } finally {
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
    _userId = null;
    _allTransactions = [];
    _filteredTransactions = [];
    _selectedFilter = 'All';
    notifyListeners();
  }
}
