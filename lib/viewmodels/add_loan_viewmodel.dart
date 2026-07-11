import 'package:flutter/material.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../models/shareholder_model.dart';

class AddLoanViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  final ShareholderRepository _shareholderRepository;
  final String? currentUserId;

  bool _isLoading = false;
  String? _errorMessage;

  double _amount = 1000.0;
  int _months = 1;
  String _purpose = 'Educational';
  ShareholderModel? _selectedBorrower;
  final List<ShareholderModel> _selectedCoMakers = [];

  List<ShareholderModel> _borrowerSearchResults = [];
  List<ShareholderModel> _coMakerSearchResults = [];

  final List<int> durationOptions = [1, 2, 3, 4, 5, 6, 12];

  AddLoanViewModel(
    this._lendingRepository,
    this._shareholderRepository, {
    this.currentUserId,
  });

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get amount => _amount;
  int get months => _months;
  String get purpose => _purpose;
  ShareholderModel? get selectedBorrower => _selectedBorrower;
  List<ShareholderModel> get selectedCoMakers => _selectedCoMakers;
  List<ShareholderModel> get borrowerSearchResults => _borrowerSearchResults;
  List<ShareholderModel> get coMakerSearchResults => _coMakerSearchResults;

  double get interestRate => 0.03; // 3% monthly example
  double get totalInterest => _amount * interestRate * _months;
  double get processingFee => _amount * 0.05;
  double get netAmountToReceive => _amount - processingFee;
  double get monthlyAmortization => (_amount + totalInterest) / _months;

  bool get isEligible => true; // Placeholder
  String? get eligibilityMessage => null;

  // Setters & Actions
  void setAmount(double value) {
    _amount = value;
    notifyListeners();
  }

  void setMonths(int value) {
    _months = value;
    notifyListeners();
  }

  void setPurpose(String value) {
    _purpose = value;
    notifyListeners();
  }

  void setBorrower(ShareholderModel? borrower) {
    _selectedBorrower = borrower;
    notifyListeners();
  }

  void setBorrowerSearchQuery(String query) async {
    if (query.isEmpty) {
      _borrowerSearchResults = [];
    } else {
      final results = await _shareholderRepository.getShareholders();
      _borrowerSearchResults = results.where((s) => 
        s.fullName.toLowerCase().contains(query.toLowerCase())).toList();
    }
    notifyListeners();
  }

  void setCoMakerSearchQuery(String query) async {
    if (query.isEmpty) {
      _coMakerSearchResults = [];
    } else {
      final results = await _shareholderRepository.getShareholders();
      _coMakerSearchResults = results.where((s) => 
        s.fullName.toLowerCase().contains(query.toLowerCase())).toList();
    }
    notifyListeners();
  }

  void toggleCoMaker(ShareholderModel coMaker) {
    if (_selectedCoMakers.any((s) => s.id == coMaker.id)) {
      _selectedCoMakers.removeWhere((s) => s.id == coMaker.id);
    } else if (_selectedCoMakers.length < 2) {
      _selectedCoMakers.add(coMaker);
    }
    notifyListeners();
  }

  Future<bool> submitLoanRequest() async {
    if (_selectedBorrower == null || _selectedCoMakers.length < 2) {
      _errorMessage = 'Missing borrower or co-makers';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _lendingRepository.submitLoanRequest({
        'shareholder_id': _selectedBorrower!.id,
        'amount': _amount,
        'months': _months,
        'purpose': _purpose,
        'co_makers': _selectedCoMakers.map((s) => s.id).toList(),
      });
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
