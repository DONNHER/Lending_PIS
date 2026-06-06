import 'package:flutter/material.dart';
import '../models/shareholder_model.dart';
import '../repositories/shareholder_repository.dart';

class ShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _repository;

  List<ShareholderModel> _shareholders = [];
  bool _isLoading = false;
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _sortBy = 'Name';
  String? _errorMessage;

  ShareholderViewModel(this._repository) {
    fetchShareholders();
  }

  List<ShareholderModel> get shareholders => _shareholders;
  bool get isLoading => _isLoading;
  int get totalRows => _totalRows;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String get sortBy => _sortBy;
  String? get errorMessage => _errorMessage;

  int get totalPages => (_totalRows / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();

  Future<void> fetchShareholders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final offset = (_currentPage - 1) * _rowsPerPage;
      _shareholders = await _repository.getShareholders(
        offset: offset,
        limit: _rowsPerPage,
        sortBy: _sortBy,
      );
      
      _totalRows = await _repository.getShareholdersCount();

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
    fetchShareholders();
  }

  void setPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      fetchShareholders();
    }
  }

  void setRowsPerPage(int rows) {
    _rowsPerPage = rows;
    _currentPage = 1;
    fetchShareholders();
  }

  Future<void> deleteShareholder(String id) async {
    try {
      await _repository.deleteShareholder(id);
      await fetchShareholders();
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }

  /// Helper method to seed data if needed
  Future<void> seedDummyData() async {
    await _repository.seedShareholders();
    await fetchShareholders();
  }
}
