import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../models/shareholder_model.dart';
import '../repositories/lending_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/shareholder_repository.dart';

class LoanDetailsViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  final TransactionRepository _transactionRepository;
  final ShareholderRepository _shareholderRepository;

  LoanModel? _loan;
  LoanRequestModel? _request;
  ShareholderModel? _borrower;
  List<TransactionModel> _paymentHistory = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _currentLoanId;

  LoanDetailsViewModel(
    this._lendingRepository, 
    this._transactionRepository,
    this._shareholderRepository,
  );

  LoanModel? get loan => _loan;
  LoanRequestModel? get request => _request;
  ShareholderModel? get borrower => _borrower;
  List<TransactionModel> get paymentHistory => _paymentHistory;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLoanDetails(String loanId, {bool forceRefresh = false}) async {
    // 🚀 GUARD: Skip fetching if we already have the data for THIS specific loan
    if (_currentLoanId == loanId && _isInitialized && !forceRefresh) {
      debugPrint('DEBUG [LoanDetailsViewModel]: Data for $loanId already cached. Skipping fetch.');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    
    // If we're switching loans, clear the previous data to avoid UI flickering
    if (_currentLoanId != loanId) {
      _loan = null;
      _request = null;
      _borrower = null;
      _paymentHistory = [];
      _isInitialized = false;
    }
    
    _currentLoanId = loanId;
    notifyListeners();

    try {
      debugPrint('DEBUG [LoanDetailsViewModel]: Fetching loan details for: $loanId');

      // 1. Try to fetch by the primary Loan ID (supports UUID)
      _loan = await _lendingRepository.getLoanById(loanId);

      // 2. Fallback: Search by the Loan Request ID if primary ID lookup failed
      if (_loan == null) {
        debugPrint('DEBUG [LoanDetailsViewModel]: Loan NOT found by ID. Trying as Loan Request ID...');
        _loan = await _lendingRepository.getLoanByLoanRequestId(loanId);
      }

      if (_loan != null) {
        debugPrint('DEBUG [LoanDetailsViewModel]: Loan found. Fetching associated request, borrower and history...');
        _request = await _lendingRepository.getLoanRequestById(_loan!.loanRequestId);
        _borrower = await _shareholderRepository.getShareholderById(_loan!.shareholderId);

        // Use the actual loan UUID for transaction history lookup
        final history = await _transactionRepository.getTransactionsByReferenceId(_loan!.id);
        _paymentHistory = history.where((tx) =>
            tx.type.toLowerCase().contains('payment')
        ).toList();
      } else {
        debugPrint('DEBUG [LoanDetailsViewModel]: Loan record NOT found. Fetching request details directly.');
        // FALLBACK: Load request data directly if loan doesn't exist yet (e.g., pending application)
        _request = await _lendingRepository.getLoanRequestById(loanId);

        if (_request != null) {
          _borrower = await _shareholderRepository.getShareholderById(_request!.shareholderId);
        } else {
          _errorMessage = 'Loan record not found.';
        }
      }
      
      _isInitialized = true;
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

  Future<bool> submitComakerDecision({
    required String loanRequestId,
    required String shareholderId,
    required ComakerStatus status,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _lendingRepository.setComakerDecision(
        loanRequestId: loanRequestId,
        comakerShareholderId: shareholderId,
        status: status,
      );
      
      // Refresh data after decision
      await fetchLoanDetails(loanRequestId, forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void handleAction(String action) {
    debugPrint('Action triggered: $action for loan $_currentLoanId');
  }

  void reset() {
    _loan = null;
    _request = null;
    _borrower = null;
    _paymentHistory = [];
    _currentLoanId = null;
    _isInitialized = false;
    notifyListeners();
  }
}