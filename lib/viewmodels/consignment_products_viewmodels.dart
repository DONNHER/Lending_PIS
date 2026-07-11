import 'package:flutter/material.dart';
import 'package:capstone_application/models/consignment_model.dart';
import 'package:capstone_application/models/consignee_model.dart';

enum ProductsViewState { idle, loading, error, success }

class ConsignmentProductsViewModel extends ChangeNotifier {
  bool _isLoading = false;
  List<ConsignmentWithDetails> _consignments = [];
  List<ConsignmentWithDetails> _allConsignments = [];
  String? _errorMessage;
  String _statusFilter = 'All';
  String _searchQuery = '';
  List<ConsigneeModel> _consignees = [];
  bool _isDropdownDataLoaded = false;

  bool get isLoading => _isLoading;
  List<ConsignmentWithDetails> get consignments => _consignments;
  List<ConsignmentWithDetails> get allConsignments => _allConsignments;
  String? get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;
  ProductsViewState get state => _isLoading ? ProductsViewState.loading : ProductsViewState.idle;
  
  bool get isDropdownDataLoaded => _isDropdownDataLoaded;
  List<ConsigneeModel> get consignees => _consignees;

  Future<void> loadConsignments() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Mock loading
      await Future.delayed(const Duration(milliseconds: 500));
      _consignees = [
        ConsigneeModel(id: '1', fullName: 'John Doe', email: 'john@example.com', phone: '123456', address: 'Address 1'),
      ];
      _allConsignments = []; // Populate with mock if needed
      _applyFilters();
      _isDropdownDataLoaded = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _consignments = _allConsignments.where((item) {
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && item.product.isActive) ||
          (_statusFilter == 'Inactive' && !item.product.isActive);
      final matchesSearch = item.product.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.product.barcode.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<bool> createConsignment({
    required String productName,
    required String barcode,
    List<int>? imageBytes,
    String? imageFileName,
    required double sellingPrice,
    required String consigneeId,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Mock logic
      await Future.delayed(const Duration(milliseconds: 800));
      await loadConsignments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(String productId, bool currentStatus) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Mock toggle
      await Future.delayed(const Duration(milliseconds: 500));
      await loadConsignments();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteConsignment(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Mock delete
      await Future.delayed(const Duration(milliseconds: 500));
      await loadConsignments();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
