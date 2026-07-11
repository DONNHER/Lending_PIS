import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/services/local_cache_service.dart';

class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  bool _isLoading = false;
  bool _isInitialized = false;

  TransactionViewModel(this._transactionRepository, {required LocalCacheService cacheService});

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _transactionRepository.getTransactions();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
