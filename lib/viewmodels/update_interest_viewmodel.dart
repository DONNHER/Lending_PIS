import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/lending_repository.dart';

class UpdateInterestViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  
  bool _isLoading = false;
  bool _isInitialized = false;
  double _currentRate = 0.032;
  List<dynamic> _history = [];

  UpdateInterestViewModel(this._lendingRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  double get currentRate => _currentRate;
  List<dynamic> get history => _history;

  Future<void> loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _currentRate = await _lendingRepository.getInterestRate();
      _history = await _lendingRepository.getInterestRateHistory();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading interest data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRate(double newRate, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _lendingRepository.updateInterestRate(
        oldRate: _currentRate,
        newRate: newRate,
        reason: reason,
        effectiveDate: DateTime.now(),
      );
      await loadData();
      return true;
    } catch (e) {
      debugPrint('Error updating interest rate: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
