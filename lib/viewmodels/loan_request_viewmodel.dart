import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/services/local_cache_service.dart';

class LoanRequestViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;

  bool _isLoading = false;
  bool _isInitialized = false;

  LoanRequestViewModel(this._lendingRepository, {required LocalCacheService cacheService});

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> fetchLoanRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _lendingRepository.getLoanRequests();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
