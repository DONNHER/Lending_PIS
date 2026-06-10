import 'dart:async';
import 'package:flutter/material.dart';
import '../models/interest_rate_history_model.dart';
import '../repositories/lending_repository.dart';
import '../services/local_cache_service.dart';

class UpdateInterestViewModel extends ChangeNotifier {
  final LendingRepository _repository;
  final LocalCacheService? _cache;

  double _currentRate = 0.0;
  int _activeLoansCount = 0;
  List<InterestRateHistoryModel> _history = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  final rateController = TextEditingController();
  final reasonController = TextEditingController();
  DateTime? _selectedEffectiveDate;

  UpdateInterestViewModel(this._repository, {LocalCacheService? cacheService}) 
      : _cache = cacheService;

  double get currentRate => _currentRate;
  int get activeLoansCount => _activeLoansCount;
  List<InterestRateHistoryModel> get history => _history;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  DateTime? get selectedEffectiveDate => _selectedEffectiveDate;

  void setEffectiveDate(DateTime date) {
    _selectedEffectiveDate = date;
    notifyListeners();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    await loadData();
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) return;

    // 1. Try to load from Cache first
    if (_cache != null && !forceRefresh) {
      final cachedData = await _cache!.getData('admin_interest_settings');
      if (cachedData != null && cachedData is Map) {
        _currentRate = (cachedData['current_rate'] as num).toDouble();
        _activeLoansCount = cachedData['active_loans_count'] as int;
        if (cachedData['history'] != null) {
          _history = (cachedData['history'] as List).map((e) => InterestRateHistoryModel.fromJson(e)).toList();
        }
        _isInitialized = true;
        notifyListeners();
      }
    }

    if (!forceRefresh && _isInitialized) {
      _performBackgroundFetch();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _performBackgroundFetch();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _performBackgroundFetch() async {
    try {
      final results = await Future.wait([
        _repository.getCurrentInterestRate().catchError((e) => 0.032),
        _repository.getActiveLoansCount().catchError((e) => 0),
        _repository.getInterestRateHistory().catchError((e) => <InterestRateHistoryModel>[]),
      ]);

      _currentRate = results[0] as double;
      _activeLoansCount = results[1] as int;
      _history = results[2] as List<InterestRateHistoryModel>;

      _isInitialized = true;

      // Save to cache
      if (_cache != null) {
        await _cache!.saveData('admin_interest_settings', {
          'current_rate': _currentRate,
          'active_loans_count': _activeLoansCount,
          'history': _history.map((e) => e.toJson()).toList(),
        });
      }
    } catch (e) {
      debugPrint('UpdateInterestVM Error: $e');
      if (!_isInitialized) _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> applyChanges() async {
    final newRateRaw = double.tryParse(rateController.text);
    if (newRateRaw == null || reasonController.text.isEmpty || _selectedEffectiveDate == null) {
      _errorMessage = 'Please fill in all required fields correctly';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRate = newRateRaw / 100; 
      final historyEntry = InterestRateHistoryModel(
        id: '',
        oldRate: _currentRate,
        newRate: newRate,
        reason: reasonController.text,
        effectiveDate: _selectedEffectiveDate!,
        createdAt: DateTime.now(),
      );

      await _repository.updateInterestRate(historyEntry);
      await loadData(forceRefresh: true);
      clearForm();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearForm() {
    rateController.clear();
    reasonController.clear();
    _selectedEffectiveDate = null;
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _isInitialized = false;
    _history = [];
    _currentRate = 0.0;
    _activeLoansCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    rateController.dispose();
    reasonController.dispose();
    super.dispose();
  }
}
