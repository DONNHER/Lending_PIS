import 'package:flutter/foundation.dart';
import '../models/consignee_model.dart';
import '../models/product_model.dart';
import '../repositories/consignee_repository.dart';
import '../repositories/consignment_products_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/storage_repository.dart';

enum ProductsViewState { idle, loading, error }

class ConsignmentProductsViewModel extends ChangeNotifier {
  final ConsignmentProductsRepository _repository;
  final ProductRepository _productRepository;
  final ConsigneeRepository _consigneeRepository;
  final StorageRepository _storageRepository;

  List<ConsignmentWithDetails> _allConsignments = [];
  ProductsViewState _state = ProductsViewState.idle;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'All';

  List<ProductModel> _products = [];
  List<ConsigneeModel> _consignees = [];
  bool _isDropdownDataLoaded = false;

  ConsignmentProductsViewModel(
    this._repository,
    this._productRepository,
    this._consigneeRepository,
    this._storageRepository,
  ) {
    _loadDropdownData();
  }

  // ─── Getters ──────────────────────────────────────────────────────────

  ProductsViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ProductsViewState.loading;
  String get statusFilter => _statusFilter;
  List<ProductModel> get products => _products;
  List<ConsigneeModel> get consignees => _consignees;
  bool get isDropdownDataLoaded => _isDropdownDataLoaded;

  // ✅ FIX: expose the raw unfiltered list so the detail page can resolve
  //    the live object by ID regardless of search/filter state.
  List<ConsignmentWithDetails> get allConsignments => _allConsignments;

  List<ConsignmentWithDetails> get consignments {
    var filtered = _allConsignments;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.product.productName.toLowerCase().contains(q) ||
            item.product.barcode.toLowerCase().contains(q) ||
            (item.consignee?.fullName.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    if (_statusFilter == 'Active') {
      filtered = filtered.where((item) => item.product.isActive).toList();
    } else if (_statusFilter == 'Inactive') {
      filtered = filtered.where((item) => !item.product.isActive).toList();
    }
    return filtered;
  }

  // ─── Dropdown Data ────────────────────────────────────────────────────

  Future<void> _loadDropdownData() async {
    try {
      _products = await _productRepository.getAll();
      _consignees = await _consigneeRepository.getAll();
      _isDropdownDataLoaded = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load form data: $e';
      notifyListeners();
    }
  }

  // ─── Consignment Methods ──────────────────────────────────────────────

  Future<void> loadConsignments() async {
    _state = ProductsViewState.loading;
    notifyListeners();
    try {
      _allConsignments = await _repository.getAll();
      _state = ProductsViewState.idle;
    } catch (e) {
      _state = ProductsViewState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
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
    _state = ProductsViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      String? productImageUrl;
      if (imageBytes != null && imageFileName != null) {
        productImageUrl = await _storageRepository.uploadFile(
          fileBytes: imageBytes,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$imageFileName',
          folder: 'product-images',
        );
      }
      await _repository.createProductWithConsignment(
        productName: productName,
        barcode: barcode,
        productImage: productImageUrl,
        sellingPrice: sellingPrice,
        consigneeId: consigneeId,
        commissionRate: commissionRate,
        capitalPrice: capitalPrice,
      );
      await loadConsignments();
      return true;
    } catch (e) {
      _state = ProductsViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStatus(String productId, bool currentStatus) async {
    try {
      await _repository.toggleProductStatus(productId, !currentStatus);
      await loadConsignments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteConsignment(int consignmentId) async {
    try {
      await _repository.delete(consignmentId);
      await loadConsignments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}