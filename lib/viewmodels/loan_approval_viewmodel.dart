import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';

class LoanApprovalViewModel extends ChangeNotifier {
  final LendingRepository _repository;
  final LoanRequestModel? initialRequest;

  List<LoanRequestModel> _approvedLoans = [];
  LoanRequestModel? _selectedLoan;
  bool _isLoading = false;
  bool _isProcessingAction = false;
  String? _errorMessage;

  LoanApprovalViewModel(this._repository, {this.initialRequest}) {
    _selectedLoan = initialRequest;
    fetchApprovedLoans();
  }

  List<LoanRequestModel> get approvedLoans => _approvedLoans;
  LoanRequestModel? get selectedLoan => _selectedLoan;
  bool get isLoading => _isLoading;
  bool get isProcessingAction => _isProcessingAction;
  String? get errorMessage => _errorMessage;

  Future<void> fetchApprovedLoans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<LoanRequestModel> loans = await _repository.getLoanRequests(status: 'approved');
      
      if (initialRequest != null) {
        final bool exists = loans.any((l) => l.id == initialRequest!.id);
        if (!exists) {
          loans.insert(0, initialRequest!);
        }
      }
      
      _approvedLoans = loans;

      if (_selectedLoan != null) {
        final index = _approvedLoans.indexWhere((l) => l.id == _selectedLoan!.id);
        if (index != -1) {
          _selectedLoan = _approvedLoans[index];
        }
      } else if (_approvedLoans.isNotEmpty) {
        _selectedLoan = _approvedLoans.first;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectLoan(String? id) {
    if (id == null) return;
    _selectedLoan = _approvedLoans.firstWhere((l) => l.id == id, orElse: () => _selectedLoan!);
    notifyListeners();
  }

  Future<bool> releaseDisbursement() async {
    if (_selectedLoan == null || _isProcessingAction) return false;

    _isProcessingAction = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = _selectedLoan!;

      // Financial calculations
      final totalInterest = request.requestedAmount * request.interestRate * request.tenureMonths;
      final totalRepayable = request.requestedAmount + totalInterest;
      final monthlyAmortization = totalRepayable / request.tenureMonths;
      final processingFee = request.requestedAmount * 0.05;

      final loan = LoanModel(
        id: 'L-${request.id}',
        loanRequestId: request.id,
        shareholderId: request.shareholderId,
        principalAmount: request.requestedAmount,
        interestRate: request.interestRate,
        tenureMonths: request.tenureMonths,
        processingFee: processingFee,
        remainingBalance: totalRepayable,
        monthlyAmortization: monthlyAmortization,
        totalRepayable: totalRepayable,
        disbursedAt: DateTime.now(),
        nextRepaymentDate: DateTime.now().add(const Duration(days: 30)),
        status: 'active',
      );

      await _repository.disburseLoan(loan);
      await fetchApprovedLoans();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }
}
