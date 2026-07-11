import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class ShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<ShareholderModel> _shareholders = [];
  List<ShareholderModel> _filteredShareholders = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;
  String _searchQuery = '';

  // Filtering/Sorting
  String _sortOrder = 'Name (A-Z)';

  ShareholderViewModel(this._shareholderRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<ShareholderModel> get shareholders => _filteredShareholders;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;
  String get sortOrder => _sortOrder;

  Future<void> fetchShareholders({int? page, int? perPage, bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_isInitialized && !forceRefresh && page == null && perPage == null) return;

    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      final result = await _shareholderRepository.getPaginatedShareholders(
        page: 1, // Get many and filter locally for now to support sorting
        perPage: 1000, 
        search: _searchQuery,
      );
      
      _shareholders = result['shareholders'];
      _applyFilters();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching shareholders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredShareholders = List.from(_shareholders);

    // Sorting
    switch (_sortOrder) {
      case 'Name (A-Z)':
        _filteredShareholders.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'Name (Z-A)':
        _filteredShareholders.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'Highest Capital':
        _filteredShareholders.sort((a, b) => b.shareCapital.compareTo(a.shareCapital));
        break;
      case 'Highest Score':
        _filteredShareholders.sort((a, b) => b.creditScore.compareTo(a.creditScore));
        break;
    }

    _totalRows = _filteredShareholders.length;
    _lastPage = (_totalRows / _rowsPerPage).ceil();
    if (_lastPage == 0) _lastPage = 1;
    
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex < _filteredShareholders.length) {
      final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredShareholders.length);
      _filteredShareholders = _filteredShareholders.sublist(startIndex, endIndex);
    } else {
      _filteredShareholders = [];
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

  void setSearch(String query) {
    _searchQuery = query;
    _currentPage = 1;
    fetchShareholders(forceRefresh: true);
  }

  void refresh() => fetchShareholders(forceRefresh: true);
}
