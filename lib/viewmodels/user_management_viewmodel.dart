import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';

class UserManagementViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  List<UserModel> _users = [];
  
  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRows = 0;
  int _rowsPerPage = 10;
  String _searchQuery = '';

  // Filtering
  String _roleFilter = 'All';
  String _statusFilter = 'All';
  String _sortOrder = 'Newest';

  UserManagementViewModel(this._userRepository);

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<UserModel> get users => _users;
  
  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalRows => _totalRows;
  int get rowsPerPage => _rowsPerPage;

  String get roleFilter => _roleFilter;
  String get statusFilter => _statusFilter;
  String get sortOrder => _sortOrder;

  Future<void> fetchUsers({int? page, int? perPage, bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_isInitialized && !forceRefresh && page == null && perPage == null) return;

    if (page != null) _currentPage = page;
    if (perPage != null) _rowsPerPage = perPage;

    _isLoading = true;
    notifyListeners();
    try {
      final result = await _userRepository.getPaginatedUsers(
        page: _currentPage,
        perPage: _rowsPerPage,
        search: _searchQuery,
        role: _roleFilter,
        status: _statusFilter,
      );
      
      _users = result['users'];
      _totalRows = result['total'];
      _lastPage = result['last_page'];
      _currentPage = result['current_page'];
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error fetching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setRoleFilter(String role) {
    _roleFilter = role;
    _currentPage = 1;
    fetchUsers(forceRefresh: true);
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _currentPage = 1;
    fetchUsers(forceRefresh: true);
  }

  void setRowsPerPage(int count) {
    _rowsPerPage = count;
    _currentPage = 1;
    fetchUsers(forceRefresh: true);
  }

  void setPage(int page) {
    _currentPage = page;
    fetchUsers(forceRefresh: true);
  }

  void setSearch(String query) {
    _searchQuery = query;
    _currentPage = 1;
    fetchUsers(forceRefresh: true);
  }

  void refresh() => fetchUsers(forceRefresh: true);
}
