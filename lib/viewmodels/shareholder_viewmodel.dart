import 'dart:async';
import 'package:flutter/material.dart';
import '../models/shareholder_model.dart';
import '../repositories/shareholder_repository.dart';
import '../services/local_cache_service.dart';

class ShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _repository;
  final LocalCacheService? _cache;

  List<ShareholderModel> _shareholders = [];
  bool _isLoading = false;
  bool _isInitialized = false; 
  int _totalRows = 0;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  String _sortBy = 'Name';
  String _selectedRole = 'All'; // Default role filter
  String? _errorMessage;

  ShareholderViewModel(this._repository, {LocalCacheService? cacheService}) : _cache = cacheService;

  List<ShareholderModel> get shareholders => _shareholders;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized; 
  int get totalRows => _totalRows;
  int get currentPage => _currentPage;
  int get rowsPerPage => _rowsPerPage;
  String get sortBy => _sortBy;
  String get selectedRole => _selectedRole;
  String? get errorMessage => _errorMessage;

  int get totalPages => (_totalRows / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();

  Future<void> fetchShareholders({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh && _shareholders.isNotEmpty) return;

    final cacheKey = 'admin_users_p${_currentPage}_s${_sortBy}_r$_selectedRole';

    // 1. Try to load from Cache first
    if (_cache != null && !forceRefresh) {
      final cached = await _cache!.getData(cacheKey);
      if (cached != null && cached is Map) {
        _shareholders = (cached['data'] as List).map((e) => ShareholderModel.fromJson(e)).toList();
        _totalRows = cached['total'] ?? 0;
        _isInitialized = true;
        notifyListeners();
      }
    }

    if (!forceRefresh && _isInitialized) {
      _performBackgroundFetch(cacheKey);
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _performBackgroundFetch(cacheKey);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _performBackgroundFetch(String cacheKey) async {
    try {
      final offset = (_currentPage - 1) * _rowsPerPage;
      
      final Future<List<ShareholderModel>> dataFuture;
      
      // 🚀 Switch between detailed shareholder view and general user view
      if (_selectedRole == 'Shareholder') {
        dataFuture = _repository.getShareholders(
          offset: offset,
          limit: _rowsPerPage,
          sortBy: _sortBy,
        );
      } else {
        dataFuture = _repository.getUsers(
          offset: offset,
          limit: _rowsPerPage,
          sortBy: _sortBy,
          role: _selectedRole,
        );
      }

      final results = await Future.wait([
        dataFuture,
        _repository.getShareholdersCount(role: _selectedRole),
      ]);

      _shareholders = results[0] as List<ShareholderModel>;
      _totalRows = results[1] as int;
      _isInitialized = true;

      // Save to cache
      if (_cache != null) {
        await _cache!.saveData(cacheKey, {
          'data': _shareholders.map((e) => e.toJson()).toList(),
          'total': _totalRows,
        });
      }
    } catch (e) {
      debugPrint('[ShareholderViewModel] Error: $e');
      if (!_isInitialized) {
        _errorMessage = e.toString();
      }
    } finally {
      notifyListeners();
    }
  }

  void setSelectedRole(String role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    _currentPage = 1;
    
    // Reset sort if it's not applicable
    if (_selectedRole != 'Shareholder' && _sortBy == 'Amount') {
      _sortBy = 'Name';
    }
    
    fetchShareholders(forceRefresh: true);
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
    _selectedRole = 'All';
    _sortBy = 'Name';
    notifyListeners();
  }
}
