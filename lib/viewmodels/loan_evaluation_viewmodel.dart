import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../models/shareholder_model.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';

class LoanEvaluationViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepo;
  final ShareholderRepository _shareholderRepo;
  LoanRequestModel _request;

  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  ShareholderModel? _shareholder;

  LoanEvaluationViewModel(
    this._lendingRepo,
    this._shareholderRepo,
    this._request,
  ) {
    _loadShareholder();
  }

  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  LoanRequestModel get request => _request;
  ShareholderModel? get shareholder => _shareholder;

  // Evaluation Metrics (Mocked for now)
  double get repaymentCapacity => 0.75;
  double get debtToIncome => 0.20;
  double get finalScore => 8.5;
  
  Color get riskColor => Colors.green;
  String get riskLevel => 'Low Risk';
  String get recommendation => 'Strongly Recommended for Approval';

  Future<void> _loadShareholder() async {
    _isLoading = true;
    notifyListeners();
    try {
      _shareholder = await _shareholderRepo.getShareholderById(_request.shareholderId);
    } catch (e) {
      _errorMessage = 'Failed to load shareholder info: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(LoanStatus status) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _lendingRepo.updateLoanRequestStatus(_request.id, status);
      _request = _request.copyWith(status: status);
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  String comakerName(String id) {
    // In a real app, we might have these names pre-loaded or fetch them
    final comaker = _request.effectiveComakers.firstWhere(
      (c) => c.shareholderId == id,
      orElse: () => LoanComaker(shareholderId: id, shareholderName: 'Unknown', status: ComakerStatus.pending),
    );
    return comaker.shareholderName;
  }
}
