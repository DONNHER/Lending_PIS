import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lending_models.dart';
import '../models/shareholder_model.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';

class AddLoanViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepo;
  final ShareholderRepository _shareholderRepo;
  final SupabaseClient _supabase = Supabase.instance.client;

  double _amount = 2000.0;
  int _months = 6;
  double _interestRate = 0.023;
  String _purpose = 'Educational';

  ShareholderModel? _selectedBorrower;
  final List<ShareholderModel> _selectedCoMakers = [];
  List<ShareholderModel> _availableShareholders = [];

  String _borrowerSearchQuery = '';
  String _coMakerSearchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;

  final List<int> durationOptions = [1, 3, 6, 12];

  AddLoanViewModel(this._lendingRepo, this._shareholderRepo) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadShareholders(),
        _fetchLiveInterestRate(),
      ]);
    } catch (e) {
      debugPrint('Initialization error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchLiveInterestRate() async {
    try {
      final liveRate = await _lendingRepo.getCurrentInterestRate();
      _interestRate = liveRate;
    } catch (e) {
      debugPrint('Error fetching live interest rate: $e');
    }
  }

  // Calculations
  double get totalInterest => _amount * _interestRate * _months;
  double get totalLoanAmount => _amount + totalInterest;
  double get totalRepayment => totalLoanAmount;
  double get monthlyAmortization => totalRepayment / _months;
  double get processingFee => _amount * 0.05;
  double get netAmountToReceive => _amount - processingFee;

  Future<void> _loadShareholders() async {
    try {
      _availableShareholders = await _shareholderRepo.getShareholders(limit: 1000);
    } catch (e) {
      debugPrint('Error loading shareholders: $e');
    }
  }

  // Getters
  double get amount => _amount;
  int get months => _months;
  double get interestRate => _interestRate;
  String get purpose => _purpose;
  ShareholderModel? get selectedBorrower => _selectedBorrower;
  List<ShareholderModel> get selectedCoMakers => _selectedCoMakers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Eligibility getters - defaulted to true/null as requested to remove the eligibility error
  bool get isEligible => true;
  String? get eligibilityMessage => null;

  /// Borrower Search: Exclude anyone already selected as a co-maker
  List<ShareholderModel> get borrowerSearchResults {
    if (_borrowerSearchQuery.isEmpty) return [];
    final query = _borrowerSearchQuery.toLowerCase();
    return _availableShareholders.where((s) {
      // Logic: If already in co-makers, don't show in borrower search
      if (_selectedCoMakers.any((cm) => cm.id == s.id)) return false;
      return s.fullName.toLowerCase().contains(query);
    }).toList();
  }

  /// Co-makers Search: Exclude current borrower and already selected co-makers
  List<ShareholderModel> get coMakerSearchResults {
    if (_coMakerSearchQuery.isEmpty) return [];
    final query = _coMakerSearchQuery.toLowerCase();
    return _availableShareholders.where((s) {
      // Logic: If is the borrower, don't show in co-maker search
      if (_selectedBorrower?.id == s.id) return false;
      // Exclude already selected co-makers
      if (_selectedCoMakers.any((cm) => cm.id == s.id)) return false;
      return s.fullName.toLowerCase().contains(query);
    }).toList();
  }

  void setBorrowerSearchQuery(String query) {
    _borrowerSearchQuery = query;
    notifyListeners();
  }

  void setCoMakerSearchQuery(String query) {
    _coMakerSearchQuery = query;
    notifyListeners();
  }

  void setBorrower(ShareholderModel? borrower) {
    _selectedBorrower = borrower;
    _borrowerSearchQuery = '';
    
    if (borrower != null) {
      // Force mutual exclusion: If they were a co-maker, they can't be anymore
      _selectedCoMakers.removeWhere((cm) => cm.id == borrower.id);
    }
    notifyListeners();
  }

  void setAmount(double value) { _amount = value; notifyListeners(); }
  void setMonths(int value) { _months = value; notifyListeners(); }
  void setPurpose(String value) { _purpose = value; notifyListeners(); }

  void toggleCoMaker(ShareholderModel shareholder) {
    if (_selectedCoMakers.any((s) => s.id == shareholder.id)) {
      _selectedCoMakers.removeWhere((s) => s.id == shareholder.id);
    } else if (_selectedCoMakers.length < 2) {
      // Force mutual exclusion: If they were the borrower, they can't be anymore
      if (_selectedBorrower?.id == shareholder.id) {
        _selectedBorrower = null;
      }
      _selectedCoMakers.add(shareholder);
      _coMakerSearchQuery = '';
    }
    notifyListeners();
  }

  Future<bool> submitLoanRequest() async {
    if (_selectedBorrower == null || _selectedCoMakers.length < 2) {
      _errorMessage = 'Missing borrower or enough comakers';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final comakerIds = _selectedCoMakers.map((c) => c.id).toList();

      final request = LoanRequestModel(
        id: '',
        shareholderId: _selectedBorrower!.id,
        shareholderName: _selectedBorrower!.fullName,
        requestedAmount: _amount,
        interestRate: _interestRate,
        tenureMonths: _months,
        purpose: _purpose,
        status: LoanStatus.pending,
        createdAt: DateTime.now(),
        loanComakers: comakerIds,
      );

      await _lendingRepo.createLoanRequest(request, comakerIds);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
