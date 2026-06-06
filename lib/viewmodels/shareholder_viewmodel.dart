import 'package:flutter/material.dart';
import '../models/shareholder_model.dart';
import '../repositories/shareholder_repository.dart';

class ShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _repository;

  List<ShareholderModel> _shareholders = [];
  bool _isLoading = false;
  bool _isInitialized = false; // 🚀 Caching flag
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _sortBy = 'Name';
  String? _errorMessage;

  ShareholderViewModel(this._repository);

  List<ShareholderModel> get shareholders => _shareholders;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; // 🚀 Getter
  int get totalRows => _totalRows;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String get sortBy => _sortBy;
  String? get errorMessage => _errorMessage;

  int get totalPages => (_totalRows / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();

  Future<void> fetchShareholders({bool forceRefresh = false}) async {
    // 🚀 Avoid redundant loading unless forced
    if (_isInitialized && !forceRefresh && _shareholders.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = (_currentPage - 1) * _rowsPerPage;
      
      // Perform fetches concurrently
      final results = await Future.wait([
        _repository.getShareholders(
          offset: offset,
          limit: _rowsPerPage,
          sortBy: _sortBy,
        ),
        _repository.getShareholdersCount(),
      ]);

      _shareholders = results[0] as List<ShareholderModel>;
      _totalRows = results[1] as int;
      _isInitialized = true;

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[ShareholderViewModel] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    _currentPage = 1;
    fetchShareholders(forceRefresh: true);
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      fetchShareholders(forceRefresh: true);
    }
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    fetchShareholders(forceRefresh: true);
  }

  Future<void> deleteShareholder(String id) async {
    try {
      await _repository.deleteShareholder(id);
      await fetchShareholders(forceRefresh: true);
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  void reset() {
    _isInitialized = false;
    _shareholders = [];
    notifyListeners();
  }

  /// Helper method to seed data if needed
  Future<void> seedDummyData() async {
    await _repository.seedShareholders();
    await fetchShareholders(forceRefresh: true);
  }
}
