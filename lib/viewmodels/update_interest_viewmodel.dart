import 'package:flutter/material.dart';
import '../models/interest_rate_history_model.dart';
import '../repositories/lending_repository.dart';

class UpdateInterestViewModel extends ChangeNotifier {
  final LendingRepository _repository;

  double _currentRate = 0.0;
  int _activeLoansCount = 0;
  List<InterestRateHistoryModel> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  UpdateInterestViewModel(this._repository) {
    _loadData();
  }

  double get currentRate => _currentRate;
  int get activeLoansCount => _activeLoansCount;
  List<InterestRateHistoryModel> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final rateController = TextEditingController();
  final reasonController = TextEditingController();
  DateTime? _selectedEffectiveDate;

  DateTime? get selectedEffectiveDate => _selectedEffectiveDate;

  void setEffectiveDate(DateTime date) {
    _selectedEffectiveDate = date;
    notifyListeners();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentRate = await _repository.getCurrentInterestRate();
      _activeLoansCount = await _repository.getActiveLoansCount();
      _history = await _repository.getInterestRateHistory();

      // Mock data for UI demo if empty
      if (_history.isEmpty) {
        _history = [
          InterestRateHistoryModel(
            id: '1',
            oldRate: 0.030,
            newRate: 0.032,
            reason: 'Board Resolution #45 - Market adjustment',
            effectiveDate: DateTime(2022, 6, 27),
            createdAt: DateTime(2022, 6, 27),
          ),
          InterestRateHistoryModel(
            id: '2',
            oldRate: 0.028,
            newRate: 0.030,
            reason: 'Quarterly review - Inflation adjustment',
            effectiveDate: DateTime(2022, 1, 15),
            createdAt: DateTime(2022, 1, 15),
          ),
        ];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
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
      final newRate = newRateRaw / 100; // Convert 3.5 to 0.035
      final historyEntry = InterestRateHistoryModel(
        id: '',
        oldRate: _currentRate,
        newRate: newRate,
        reason: reasonController.text,
        effectiveDate: _selectedEffectiveDate!,
        createdAt: DateTime.now(),
      );

      await _repository.updateInterestRate(historyEntry);
      await _loadData();
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

  @override
  void dispose() {
    rateController.dispose();
    reasonController.dispose();
    super.dispose();
  }
}
