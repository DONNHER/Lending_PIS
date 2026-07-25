import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import '../utils/csv_exporter.dart';
import 'package:intl/intl.dart';

class UpdateInterestViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  
  bool _isLoading = false;
  bool _isInitialized = false;
  double _currentRate = 0.032;
  List<dynamic> _history = [];
  List<dynamic> _filteredHistory = [];

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;
  String _sortOrder = 'Newest';

  UpdateInterestViewModel(this._lendingRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  double get currentRate => _currentRate;
  List<dynamic> get history => _filteredHistory;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;
  String get sortOrder => _sortOrder;
  DateTime? _lastViewedAt;

  int get newCount {
    if (_lastViewedAt == null) return 0;
    return _history.where((item) {
      final dateStr = item['created_at'] ?? item['effective_date'];
      if (dateStr == null) return false;
      return DateTime.parse(dateStr).isAfter(_lastViewedAt!);
    }).length;
  }

  void markAsViewed() {
    _lastViewedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_isInitialized && !forceRefresh) return;
    
    _isLoading = true;
    notifyListeners();
    try {
      _currentRate = await _lendingRepository.getInterestRate();
      _history = await _lendingRepository.getInterestRateHistory();
      _applyFilters();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading interest data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredHistory = List.from(_history);

    // Sorting
    switch (_sortOrder) {
      case 'Newest':
        _filteredHistory.sort((a, b) => 
          DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
        );
        break;
      case 'Oldest':
        _filteredHistory.sort((a, b) => 
          DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at']))
        );
        break;
    }

    _totalRows = _filteredHistory.length;
    _lastPage = (_totalRows / _rowsPerPage).ceil();
    if (_lastPage == 0) _lastPage = 1;
    
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex < _filteredHistory.length) {
      final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredHistory.length);
      _filteredHistory = _filteredHistory.sublist(startIndex, endIndex);
    } else {
      _filteredHistory = [];
    }
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

  Future<bool> updateRate(double newRate, String reason) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _lendingRepository.updateInterestRate(
        oldRate: _currentRate,
        newRate: newRate,
        reason: reason,
        effectiveDate: DateTime.now(),
      );
      await loadData(forceRefresh: true);
      return true;
    } catch (e) {
      debugPrint('Error updating interest rate: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() => loadData(forceRefresh: true);

  void exportHistoryToCsv() {
    if (_history.isEmpty) return;

    final headers = ['Date', 'Old Rate', 'New Rate', 'Reason'];
    final rows = _history.map((item) {
      final dateStr = item['created_at'] ?? item['effective_date'] ?? DateTime.now().toIso8601String();
      final date = DateTime.parse(dateStr);
      final oldRate = (double.tryParse(item['old_rate'].toString()) ?? 0.0) * 100;
      final newRate = (double.tryParse(item['new_rate'].toString()) ?? 0.0) * 100;
      
      return [
        "'${DateFormat('yyyy-MM-dd HH:mm:ss').format(date)}",
        '${oldRate.toStringAsFixed(1)}%',
        '${newRate.toStringAsFixed(1)}%',
        item['reason'] ?? 'N/A',
      ];
    }).toList();

    CsvExporter.exportToCsv(
      headers: headers,
      rows: rows,
      fileName: 'interest_rate_history_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}',
    );
  }
}
