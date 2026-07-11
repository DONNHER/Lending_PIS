import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/services/local_cache_service.dart';

class UpdateInterestViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isInitialized = false;

  UpdateInterestViewModel(LendingRepository lendingRepository, {required LocalCacheService cacheService});

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1));
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
