import 'package:flutter/material.dart';
import '../models/lending_models.dart';
import '../repositories/transaction_repository.dart';

/// Admin transactions list: only **Loan Disbursement** rows (actual fund releases).
class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _repository;

  static const List<String> _loanTxnTypes = ['Loan Disbursement', 'Loan Payment'];

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _selectedStatus = 'All';
  String? _errorMessage;
  bool _isDisposed = false;

  TransactionViewModel(this._repository) {
    fetchTransactions();
  }

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  int get totalRows => _totalRows;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String get selectedStatus => _selectedStatus;
  String? get errorMessage => _errorMessage;

  int get totalPages => (_totalRows / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> fetchTransactions() async {
    if (_isDisposed) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = (_currentPage - 1) * _rowsPerPage;
      final fetchedTransactions = await _repository.getTransactions(
        offset: offset,
        limit: _rowsPerPage,
        typesIn: _loanTxnTypes,
        status: _selectedStatus,
      );

      final fetchedCount = await _repository.getTransactionsCount(
        typesIn: _loanTxnTypes,
        status: _selectedStatus,
      );

      if (!_isDisposed) {
        _transactions = fetchedTransactions;
        _totalRows = fetchedCount;
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = e.toString();
      }
      debugPrint('[TransactionViewModel] Error: $e');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setStatus(String status) {
    _selectedStatus = status;
    _currentPage = 1;
    fetchTransactions();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      fetchTransactions();
    }
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    fetchTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await fetchTransactions();
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }
}
