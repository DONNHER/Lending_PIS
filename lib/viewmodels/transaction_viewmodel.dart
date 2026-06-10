import 'dart:async';
import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/transaction_repository.dart';
import '../services/local_cache_service.dart';

class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _repository;
  final LocalCacheService? _cache;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isInitialized = false; 
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _selectedStatus = 'All';
  String? _errorMessage;
  bool _isDisposed = false;

  TransactionViewModel(this._repository, {LocalCacheService? cacheService}) : _cache = cacheService;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; 
  int get totalRows => _totalRows;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String get selectedStatus => _selectedStatus;
  String? get errorMessage => _errorMessage;

  int get totalPages => (_totalRows / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    if (_isDisposed) return;
    
    // If already loading, don't trigger another fetch
    if (_isLoading) return;

    final cacheKey = 'admin_transactions_p${_currentPage}_s$_selectedStatus';

    // 1. Load from Cache
    if (_cache != null && !forceRefresh && !_isInitialized) {
      final cached = await _cache!.getData(cacheKey);
      if (cached != null && cached is Map) {
        _transactions = (cached['data'] as List).map((e) => TransactionModel.fromJson(e)).toList();
        _totalRows = cached['total'] ?? 0;
        _isInitialized = true;
        notifyListeners();
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = (_currentPage - 1) * _rowsPerPage;
      
      // We pass null for typesIn to fetch ALL transactions from the table
      final results = await Future.wait([
        _repository.getTransactions(
          offset: offset,
          limit: _rowsPerPage,
          typesIn: null, // Fetch everything
          status: _selectedStatus,
        ),
        _repository.getTransactionsCount(
          typesIn: null, // Count everything
          status: _selectedStatus,
        ),
      ]);

      if (!_isDisposed) {
        _transactions = results[0] as List<TransactionModel>;
        _totalRows = results[1] as int;
        _isInitialized = true;

        // Save to cache
        if (_cache != null) {
          await _cache!.saveData(cacheKey, {
            'data': _transactions.map((e) => e.toJson()).toList(),
            'total': _totalRows,
          });
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString();
      }
      debugPrint('[TransactionViewModel] Error: $e');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setStatus(String status) {
    _selectedStatus = status;
    _currentPage = 1;
    fetchTransactions(forceRefresh: true);
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      fetchTransactions(forceRefresh: true);
    }
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    fetchTransactions(forceRefresh: true);
  }

  void reset() {
    _isInitialized = false;
    _transactions = [];
    _currentPage = 1;
    _selectedStatus = 'All';
    notifyListeners();
  }
}
