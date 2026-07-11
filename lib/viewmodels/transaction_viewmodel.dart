import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/models/transaction_model.dart';

class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<TransactionModel> _transactions = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;

  TransactionViewModel(this._transactionRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<TransactionModel> get transactions => _transactions;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;

  Future<void> fetchTransactions({int? page, int? perPage}) async {
    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      final result = await _transactionRepository.getPaginatedTransactions(
        page: _currentPage,
        perPage: _rowsPerPage,
      );
      
      _transactions = result['transactions'];
      _totalRows = result['total'];
      _lastPage = result['last_page'];
      _currentPage = result['current_page'];
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    fetchTransactions();
  }

  void setPage(int page) {
    _currentPage = page;
    fetchTransactions();
  }

  void refresh() => fetchTransactions();
}
