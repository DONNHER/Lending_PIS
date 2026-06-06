import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../repositories/transaction_repository.dart';

class LoanDetailsViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  final TransactionRepository _transactionRepository;
  final String loanId;

  LoanModel? _loan;
  LoanRequestModel? _request;
  List<TransactionModel> _paymentHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  LoanDetailsViewModel(this._lendingRepository, this._transactionRepository, this.loanId) {
    debugPrint('DEBUG [LoanDetailsViewModel]: Initializing for Loan ID: $loanId');
    fetchLoanDetails();
  }

  LoanModel? get loan => _loan;
  LoanRequestModel? get request => _request;
  List<TransactionModel> get paymentHistory => _paymentHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLoanDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('DEBUG [LoanDetailsViewModel]: Fetching loan from repo...');

      // 1. Try to fetch by the primary Loan ID (supports UUID)
      _loan = await _lendingRepository.getLoanById(loanId);

      // 2. Fallback: Search by the Loan Request ID if primary ID lookup failed
      if (_loan == null) {
        debugPrint('DEBUG [LoanDetailsViewModel]: Loan NOT found by ID. Trying as Loan Request ID...');
        _loan = await _lendingRepository.getLoanByLoanRequestId(loanId);
      }

      if (_loan != null) {
        debugPrint('DEBUG [LoanDetailsViewModel]: Loan found. Fetching associated request and history...');
        _request = await _lendingRepository.getLoanRequestById(_loan!.loanRequestId);

        // Use the actual loan UUID for transaction history lookup
        final history = await _transactionRepository.getTransactionsByReferenceId(_loan!.id);
        _paymentHistory = history.where((tx) =>
            tx.type.toLowerCase().contains('payment')
        ).toList();
        debugPrint('DEBUG [LoanDetailsViewModel]: Fetch successful. Payments found: ${_paymentHistory.length}');
      } else {
        debugPrint('DEBUG [LoanDetailsViewModel]: Loan record NOT found. Fetching request details directly.');

        // FALLBACK: Load request data directly if loan doesn't exist yet (e.g., pending application)
        _request = await _lendingRepository.getLoanRequestById(loanId);

        if (_request == null) {
          _errorMessage = 'Loan record not found.';
        }
      }
    } catch (e, stack) {
      debugPrint('DEBUG [LoanDetailsViewModel] ERROR: $e');
      debugPrint('STACKTRACE: $stack');
      _errorMessage = 'Failed to load details: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('DEBUG [LoanDetailsViewModel]: fetchLoanDetails finished.');
    }
  }

  void handleAction(String action) {
    debugPrint('Action triggered: $action for loan $loanId');
  }
}
