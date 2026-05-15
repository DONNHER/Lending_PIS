import 'package:capstone_application/models/lending_models/transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:capstone_application/repositories/lending_repository/transactions_repository.dart';

enum TransactionViewState { idle, loading, error }

class TransactionsViewModel extends ChangeNotifier {
  final TransactionsRepository _transactionsRepo;

  List<TransactionEntry> _allTransactions = [];
  List<TransactionEntry> _filteredTransactions = [];
  TransactionViewState _state = TransactionViewState.idle;
  String? _errorMessage;

  TransactionsViewModel({
    required TransactionsRepository transactionsRepository,
  }) : _transactionsRepo = transactionsRepository;

  // Getters
  List<TransactionEntry> get transactions => _filteredTransactions;
  TransactionViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == TransactionViewState.loading;

  /// Load all financial events from the transactions repository
  Future<void> loadTransactions() async {
    _state = TransactionViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _transactionsRepo.getAllTransactions();
      final List<TransactionEntry> entries = results;

      // Sort by date descending
      entries.sort((a, b) => b.date.compareTo(a.date));
      
      _allTransactions = entries;
      _filteredTransactions = List.from(_allTransactions);
      
      _state = TransactionViewState.idle;
    } catch (e) {
      _state = TransactionViewState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// NEW: Records a loan repayment
  Future<bool> recordRepayment({
    required int loanId,
    required double amount,
    required String method,
  }) async {
    try {
      _state = TransactionViewState.loading;
      notifyListeners();

      final data = {
        'loan_id': loanId,
        'amount': amount,
        'payment_method': method,
        'payment_date': DateTime.now().toIso8601String(),
      };

      await _transactionsRepo.createRepayment(data);
      
      // Also log as a transaction movement if your system uses both tables
      await _transactionsRepo.logFundMovement(
        amount: amount,
        type: 'repayment',
        referenceId: 'PYM-$loanId-${DateTime.now().millisecondsSinceEpoch}',
        description: 'Loan Repayment for Loan #$loanId',
      );

      await loadTransactions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = TransactionViewState.error;
      notifyListeners();
      return false;
    }
  }

  /// Filter transactions by type
  void filterByType(TransactionType? type) {
    if (type == null) {
      _filteredTransactions = List.from(_allTransactions);
    } else {
      _filteredTransactions = _allTransactions
          .where((t) => t.type == type)
          .toList();
    }
    notifyListeners();
  }

  /// Record a manual adjustment, fee, or fund movement
  Future<bool> recordManualTransaction({
    required double amount,
    required TransactionType type,
    required String description,
  }) async {
    try {
      await _transactionsRepo.logFundMovement(
        amount: amount,
        type: type.name, 
        referenceId: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
        description: description,
      );
      
      await loadTransactions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    _state = TransactionViewState.idle;
    notifyListeners();
  }
}