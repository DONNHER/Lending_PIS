import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class ShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<ShareholderModel> _shareholders = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;
  String _searchQuery = '';

  ShareholderViewModel(this._shareholderRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<ShareholderModel> get shareholders => _shareholders;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;

  Future<void> fetchShareholders({int? page, int? perPage, bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_isInitialized && !forceRefresh && page == null && perPage == null) return;

    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      final result = await _shareholderRepository.getPaginatedShareholders(
        page: _currentPage,
        perPage: _rowsPerPage,
        search: _searchQuery,
      );
      
      _shareholders = result['shareholders'];
      _totalRows = result['total'];
      _lastPage = result['last_page'];
      _currentPage = result['current_page'];
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching shareholders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    fetchShareholders();
  }

  void setPage(int page) {
    _currentPage = page;
    fetchShareholders();
  }

  void setSearch(String query) {
    _searchQuery = query;
    _currentPage = 1;
    fetchShareholders();
  }

  void refresh() => fetchShareholders(forceRefresh: true);
}
