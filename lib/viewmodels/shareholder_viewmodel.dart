import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/services/local_cache_service.dart';

class ShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepository;

  bool _isLoading = false;
  bool _isInitialized = false;

  ShareholderViewModel(this._shareholderRepository, {required LocalCacheService cacheService});

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> fetchShareholders() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _shareholderRepository.getShareholders();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
