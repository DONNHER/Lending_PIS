import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../models/transaction_model.dart';
import '../repositories/lending_repository.dart';

class LoanPaymentViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepo;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  LoanModel? _loan;
  LoanRequestModel? _request;
  List<TransactionModel> _paymentHistory = [];
  TransactionModel? _lastTransaction;

  LoanPaymentViewModel(this._lendingRepo);

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  LoanModel? get loan => _loan;
  LoanRequestModel? get request => _request;
  List<TransactionModel> get paymentHistory => _paymentHistory;
  TransactionModel? get lastTransaction => _lastTransaction;

  static const List<String> paymentMethods = ['Cash', 'Bank Transfer', 'G-Cash'];

  double get suggestedAmount {
    if (_loan == null) return 0.0;
    return _loan!.monthlyAmortization;
  }

  Future<void> load({LoanRequestModel? initialRequest, String? loanId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (loanId != null && loanId.isNotEmpty && loanId != 'null') {
        _loan = await _lendingRepo.getLoanById(loanId);
        if (_loan != null) {
          _request = await _lendingRepo.getLoanRequestById(_loan!.loanRequestId);
          _paymentHistory = await _lendingRepo.getPaymentHistory(loanId);
        }
      } else if (initialRequest != null) {
        _request = initialRequest;
        _loan = await _lendingRepo.getLoanByLoanRequestId(initialRequest.id);
        if (_loan != null) {
          _paymentHistory = await _lendingRepo.getPaymentHistory(_loan!.id);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitPayment({required double amount, required String method}) async {
    if (_loan == null) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tx = await _lendingRepo.recordPayment(
        loanId: _loan!.id,
        amount: amount,
        method: method,
      );
      
      if (tx != null) {
        _lastTransaction = tx;
        // Refresh loan data to get updated balance
        _loan = await _lendingRepo.getLoanById(_loan!.id);
        _paymentHistory = await _lendingRepo.getPaymentHistory(_loan!.id);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
