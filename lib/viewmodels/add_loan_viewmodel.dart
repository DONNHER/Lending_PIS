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
  bool _hasInteracted = false;

  double _amount = 1000.0;
  int _months = 1;
  String _purpose = 'Educational';
  ShareholderModel? _selectedBorrower;
  final List<ShareholderModel> _selectedCoMakers = [];

  List<ShareholderModel> _borrowerSearchResults = [];
  List<ShareholderModel> _coMakerSearchResults = [];

  final List<int> durationOptions = [1, 2, 3, 4, 5, 6, 12];

  double _interestRate = 0.032; // Default fallback

  AddLoanViewModel(
    this._lendingRepository,
    this._shareholderRepository, {
    this.currentUserId,
    ShareholderModel? initialShareholder,
  }) : _selectedBorrower = initialShareholder;

  Future<void> init() async {
    try {
      _interestRate = await _lendingRepository.getInterestRate();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching interest rate: $e');
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasInteracted => _hasInteracted;
  bool get hasDraftData =>
      _selectedBorrower != null ||
      _amount != 1000.0 ||
      _months != 1 ||
      _purpose != 'Educational' ||
      _selectedCoMakers.isNotEmpty;
  double get amount => _amount;
  int get months => _months;
  String get purpose => _purpose;
  ShareholderModel? get selectedBorrower => _selectedBorrower;
  List<ShareholderModel> get selectedCoMakers => _selectedCoMakers;
  List<ShareholderModel> get borrowerSearchResults => _borrowerSearchResults;
  List<ShareholderModel> get coMakerSearchResults => _coMakerSearchResults;

  double get interestRate => _interestRate;
  double get totalInterest => _amount * interestRate * _months;
  double get processingFee => _amount * 0.05;
  double get netAmountToReceive => _amount - processingFee;
  double get monthlyAmortization => (_amount + totalInterest) / _months;

  bool get isEligible => true; // Placeholder
  String? get eligibilityMessage => null;
  String? get borrowerValidationMessage =>
      (!hasInteracted || _selectedBorrower != null)
          ? null
          : 'Select a borrower to continue.';
  String? get coMakerValidationMessage =>
      (!hasInteracted || _selectedCoMakers.length >= 2)
          ? null
          : 'Select 2 co-makers to continue.';
  String? get amountValidationMessage => (!hasInteracted || _amount >= 500)
      ? null
      : 'The minimum loan amount is ₱500.';

  // Setters & Actions
  void setAmount(double value) {
    _amount = value;
    _hasInteracted = true;
    notifyListeners();
  }

  void setMonths(int value) {
    _months = value;
    _hasInteracted = true;
    notifyListeners();
  }

  void setPurpose(String value) {
    _purpose = value;
    _hasInteracted = true;
    notifyListeners();
  }

  void setBorrower(ShareholderModel? borrower) {
    _selectedBorrower = borrower;
    _hasInteracted = true;
    notifyListeners();
  }

  void setBorrowerSearchQuery(String query) async {
    if (query.isEmpty) {
      _borrowerSearchResults = [];
    } else {
      final results = await _shareholderRepository.getShareholders();
      _borrowerSearchResults = results
          .where((s) => s.fullName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void setCoMakerSearchQuery(String query) async {
    if (query.isEmpty) {
      _coMakerSearchResults = [];
    } else {
      final results = await _shareholderRepository.getShareholders();
      _coMakerSearchResults = results
          .where((s) => s.fullName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void toggleCoMaker(ShareholderModel coMaker) {
    _hasInteracted = true;
    if (_selectedCoMakers.any((s) => s.id == coMaker.id)) {
      _selectedCoMakers.removeWhere((s) => s.id == coMaker.id);
    } else if (_selectedCoMakers.length < 2) {
      _selectedCoMakers.add(coMaker);
    }
    notifyListeners();
  }

  void markFormInteracted() {
    _hasInteracted = true;
    notifyListeners();
  }

  void resetDraft() {
    _amount = 1000.0;
    _months = 1;
    _purpose = 'Educational';
    _selectedBorrower = null;
    _selectedCoMakers.clear();
    _hasInteracted = false;
    _errorMessage = null;
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
        'requested_amount': _amount,
        'interest_rate': _interestRate,
        'months': _months,
        'purpose': _purpose,
        'comaker_ids': _selectedCoMakers.map((s) => s.id).toList(),
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
