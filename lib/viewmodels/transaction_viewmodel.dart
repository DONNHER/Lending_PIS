import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/models/transaction_model.dart';
import '../utils/csv_exporter.dart';
import 'package:intl/intl.dart';

class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;

  // Filtering
  String _typeFilter = 'All';
  String _statusFilter = 'All';
  String _sortOrder = 'Newest';

  TransactionViewModel(this._transactionRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<TransactionModel> get transactions => _filteredTransactions;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;

  String get typeFilter => _typeFilter;
  String get statusFilter => _statusFilter;
  String get sortOrder => _sortOrder;

  DateTime? _lastViewedAt;

  int get newCount {
    if (_lastViewedAt == null) return 0;
    return _transactions.where((t) => t.date.isAfter(_lastViewedAt!)).length;
  }

  void markAsViewed() {
    _lastViewedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> fetchTransactions({int? page, int? perPage, bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_isInitialized && !forceRefresh && page == null && perPage == null) return;
    
    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      final result = await _transactionRepository.getTransactions();
      _transactions = result;
      _applyFilters();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredTransactions = List.from(_transactions);

    // Filter by Type
    if (_typeFilter != 'All') {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.type.toLowerCase().contains(_typeFilter.toLowerCase())
      ).toList();
    }

    // Filter by Status
    if (_statusFilter != 'All') {
      _filteredTransactions = _filteredTransactions.where((t) => 
        t.status.toLowerCase() == _statusFilter.toLowerCase()
      ).toList();
    }

    // Sorting
    switch (_sortOrder) {
      case 'Newest':
        _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Oldest':
        _filteredTransactions.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Highest Amount':
        _filteredTransactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Lowest Amount':
        _filteredTransactions.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    _totalRows = _filteredTransactions.length;
    _lastPage = (_totalRows / _rowsPerPage).ceil();
    if (_lastPage == 0) _lastPage = 1;
    
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex < _filteredTransactions.length) {
      final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredTransactions.length);
      _filteredTransactions = _filteredTransactions.sublist(startIndex, endIndex);
    } else {
      _filteredTransactions = [];
    }
  }

  void setTypeFilter(String type) {
    _typeFilter = type;
    _currentPage = 1;
    _applyFilters();
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _currentPage = 1;
    _applyFilters();
    notifyListeners();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    _applyFilters();
    notifyListeners();
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    _applyFilters();
    notifyListeners();
  }

  void setPage(int page) {
    _currentPage = page;
    _applyFilters();
    notifyListeners();
  }

  void refresh() => fetchTransactions(forceRefresh: true);

  void exportToCsv() {
    if (_transactions.isEmpty) return;

    final headers = ['Date', 'Transaction ID', 'Client', 'Type', 'Method', 'Amount', 'Status'];
    final rows = _transactions.map((tx) => [
      "'${DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.date)}",
      tx.id,
      tx.clientName,
      tx.type,
      tx.method,
      tx.amount.toStringAsFixed(2),
      tx.status.toUpperCase(),
    ]).toList();

    CsvExporter.exportToCsv(
      headers: headers,
      rows: rows,
      fileName: 'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
    );
  }
}
