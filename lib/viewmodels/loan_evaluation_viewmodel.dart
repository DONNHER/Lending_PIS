import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../models/shareholder_model.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';

class LoanEvaluationViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepo;
  final ShareholderRepository _shareholderRepo;
  final LoanRequestModel request;

  ShareholderModel? _shareholder;
  bool _isLoading = true;
  String? _errorMessage;

  LoanEvaluationViewModel(this._lendingRepo, this._shareholderRepo, this.request) {
    _init();
  }

  ShareholderModel? get shareholder => _shareholder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    try {
      _shareholder = await _shareholderRepo.getShareholderById(request.shareholderId);
      // Fallback for demo/dummy data if shareholder not found
      _shareholder ??= ShareholderModel(
        id: request.shareholderId,
        userId: '',
        firstName: request.shareholderName.split(' ').first,
        lastName: request.shareholderName.contains(' ') ? request.shareholderName.split(' ').last : '',
        fullName: request.shareholderName,
        email: '',
        contactNumber: '',
        address: '',
        totalShareCapital: 10000.0,
        creditScore: 750,
      );

      for (final sid in request.loanComakers) {
        final sh = await _shareholderRepo.getShareholderById(sid);
        _comakerNames[sid] = sh?.fullName ?? 'Co-maker';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  final Map<String, String> _comakerNames = {};
  String comakerName(String shareholderId) => _comakerNames[shareholderId] ?? 'Co-maker';

  Future<bool> updateStatus(LoanStatus status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (request.id.isNotEmpty) {
        LoanRequestModel? payload = request;
        if (status == LoanStatus.approved) {
          payload = await _lendingRepo.getLoanRequestById(request.id) ?? request;
          final block = payload.comakerApprovalBlockReason;
          if (block != null) {
            _errorMessage = block;
            return false;
          }
        }
        await _lendingRepo.updateLoanRequestStatus(request.id, status, request: payload);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculation helpers for evaluation
  String get riskLevel {
    final score = _shareholder?.creditScore ?? 0;
    if (score >= 750) return 'LOW RISK';
    if (score >= 650) return 'MEDIUM RISK';
    return 'HIGH RISK';
  }

  Color get riskColor {
    final level = riskLevel;
    if (level == 'LOW RISK') return Colors.green;
    if (level == 'MEDIUM RISK') return Colors.orange;
    return Colors.red;
  }

  String get recommendation {
    final score = _shareholder?.creditScore ?? 0;
    if (score >= 700) return 'Approve';
    if (score >= 600) return 'Review';
    return 'Reject';
  }

  double get repaymentCapacity {
    if (_shareholder == null || request.requestedAmount == 0) return 0.5;
    double ratio = _shareholder!.totalShareCapital / request.requestedAmount;
    if (ratio >= 2) return 0.95;
    if (ratio >= 1) return 0.85;
    if (ratio >= 0.5) return 0.70;
    return 0.50;
  }
  
  double get debtToIncome => 0.30; // Constant placeholder for now
  
  double get finalScore {
    final score = _shareholder?.creditScore ?? 0;
    // Simple 1-10 score based on credit score (70%) and repayment capacity (30%)
    double base = (score / 850.0) * 7 + (repaymentCapacity * 3);
    return base > 10 ? 10.0 : base;
  }

  double get monthlyAmortization {
    // Total = Principal + (Principal * Rate * Months)
    final totalInterest = request.requestedAmount * request.interestRate * request.tenureMonths;
    final totalRepayment = request.requestedAmount + totalInterest;
    return totalRepayment / request.tenureMonths;
  }
}
