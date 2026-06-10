import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';

class LoanPaymentViewModel extends ChangeNotifier {
  final LendingRepository _lending;

  LoanModel? _loan;
  LoanRequestModel? _request;
  List<TransactionModel> _paymentHistory = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  TransactionModel? _lastTransaction;

  // Safely cache the initial incoming entity payload container
  LoanRequestModel? _originalIncomingRequest;

  static const List<String> paymentMethods = ['Cash Only'];

  LoanPaymentViewModel(this._lending);

  LoanModel? get loan => _loan;
  LoanRequestModel? get request => _request;
  List<TransactionModel> get paymentHistory => _paymentHistory;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  TransactionModel? get lastTransaction => _lastTransaction;

  double get suggestedAmount {
    final l = _loan;
    if (l == null) return 0;
    final cap = l.remainingBalance;
    if (cap <= 0) return 0;
    final monthly = l.monthlyAmortization;
    if (monthly <= 0) return cap;
    return monthly < cap ? monthly : cap;
  }

  Future<void> load({LoanRequestModel? initialRequest, String? loanId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (initialRequest != null) {
      _originalIncomingRequest = initialRequest;
      debugPrint('DEBUG [LoanPaymentViewModel]: Cached original incoming request instance for ID: ${initialRequest.id}');
    }

    try {
      LoanModel? resolved;
      if (loanId != null && loanId.isNotEmpty) {
        debugPrint('DEBUG [LoanPaymentViewModel]: Attempting load using loanId: $loanId');
        resolved = await _lending.getLoanById(loanId);
      } else if (initialRequest != null && initialRequest.id.isNotEmpty) {
        debugPrint('DEBUG [LoanPaymentViewModel]: Attempting load using request ID: ${initialRequest.id}');
        resolved = await _lending.getLoanByLoanRequestId(initialRequest.id);
      }

      _loan = resolved;
      if (_loan != null) {
        debugPrint('DEBUG [LoanPaymentViewModel]: Loan entry fetched. UUID target: ${_loan!.id}, cross-reference requestId: ${_loan!.loanRequestId}');

        // Fetch payment history for this loan
        _paymentHistory = await _lending.getRecentLoanTransactions(limit: 50, loanId: _loan!.id);

        // Wrap this secondary fetch so raw key mismatches don't poison state on startup
        try {
          _request = await _lending.getLoanRequestById(_loan!.loanRequestId);
        } catch (requestError) {
          debugPrint('DEBUG [LoanPaymentViewModel]: Secondary hydration skipped. Reverting to cached request: $requestError');
          _request = _originalIncomingRequest;
        }

      } else {
        _errorMessage = 'No active loan record found for this borrower. The loan may not be disbursed yet.';
        debugPrint('DEBUG [LoanPaymentViewModel]: Validation Alert: _loan resolved as null.');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DEBUG [LoanPaymentViewModel]: Exception caught inside load pipeline: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitPayment({
    required double amount,
    required String method,
  }) async {
    if (_loan == null) {
      debugPrint('DEBUG [LoanPaymentViewModel]: Cannot submit payment, current loan instance state is null.');
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _lastTransaction = null;
    notifyListeners();

    try {
      debugPrint('DEBUG [LoanPaymentViewModel]: Submitting payment via Loan UUID: ${_loan!.id}');
      _lastTransaction = await _lending.recordLoanPayment(
        loanId: _loan!.id,
        amount: amount,
        method: method,
      );
      
      if (_lastTransaction == null) {
         throw Exception('Payment was recorded but no transaction data was returned.');
      }
    } catch (e) {
      debugPrint('DEBUG [LoanPaymentViewModel]: Payment submission failed: $e');
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }

    // 🔄 Post-Payment Hydration Pipeline
    try {
      LoanRequestModel? refreshTarget = _request ?? _originalIncomingRequest;

      if (refreshTarget != null) {
        debugPrint('DEBUG [LoanPaymentViewModel]: Triggering post-payment state refresh using request string key: ${refreshTarget.id}');
        await load(initialRequest: refreshTarget);
      } else {
        debugPrint('DEBUG [LoanPaymentViewModel]: No structural schema models found. Re-polling via loan UUID line.');
        await load(loanId: _loan!.id);
      }

      if (_errorMessage != null) {
        debugPrint('DEBUG [LoanPaymentViewModel]: Payment saved but post-reload failed: $_errorMessage');
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('DEBUG [LoanPaymentViewModel]: Critical post-load exception caught: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
