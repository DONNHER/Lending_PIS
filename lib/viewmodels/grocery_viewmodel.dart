import 'package:flutter/foundation.dart';
import '../models/grocery_batch_model.dart';
import '../repositories/grocery_repository.dart';

enum GroceryState { idle, loading, error }

class GroceryViewModel extends ChangeNotifier {
  final GroceryRepository _repository;

  List<GroceryWithDetails> _groceries = [];
  GroceryState _state = GroceryState.idle;
  String? _errorMessage;
  String _searchQuery = '';
  String _filter = 'All'; // All | Active | Inactive
  bool _isInitialized = false; // 🚀 Caching flag

  GroceryViewModel(this._repository);

  // ─── Getters ──────────────────────────────────────────────────────────

  List<GroceryWithDetails> get groceries => _filteredGroceries;
  List<GroceryWithDetails> get allGroceries => _groceries;
  GroceryState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == GroceryState.loading;
  bool get isInitialized => _isInitialized; // 🚀 Initialization status
  String get searchQuery => _searchQuery;
  String get filter => _filter;

  List<GroceryWithDetails> get _filteredGroceries {
    final q = _searchQuery.toLowerCase();
    return _groceries.where((g) {
      final matchQ =
          g.product.productName.toLowerCase().contains(q) ||
          g.product.barcode.toLowerCase().contains(q);
      final matchF =
          _filter == 'All' ||
          (_filter == 'Active' && g.product.isActive) ||
          (_filter == 'Inactive' && !g.product.isActive);
      return matchQ && matchF;
    }).toList();
  }

  // ─── Computed Properties ──────────────────────────────────────────────

  int getTotalStock(GroceryWithDetails grocery) {
    return grocery.batches.fold(
      0,
      (sum, batch) => sum + batch.remainingQuantity,
    );
  }

  double getAvgCostPrice(GroceryWithDetails grocery) {
    final active = grocery.batches
        .where((b) => b.remainingQuantity > 0)
        .toList();
    if (active.isEmpty) return 0;
    return active.fold(0.0, (sum, b) => sum + b.capitalPrice) / active.length;
  }

  // ─── Methods ──────────────────────────────────────────────────────────

  Future<void> loadGroceries({bool forceRefresh = false}) async {
    // 🚀 Avoid redundant loading unless forced
    if (_isInitialized && !forceRefresh && _groceries.isNotEmpty) return;

    _state = GroceryState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _groceries = await _repository.getAll();
      _isInitialized = true;
      _state = GroceryState.idle;
      debugPrint('Loaded ${_groceries.length} grocery products');
    } catch (e) {
      _state = GroceryState.error;
      _errorMessage = e.toString();
      debugPrint('Error loading grocery products: $e');
    }
    notifyListeners();
  }

  void searchGroceries(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<bool> createProduct({
    required String productName,
    required String barcode,
    String? productImage,
    required double sellingPrice,
  }) async {
    try {
      final grocery = await _repository.createProduct(
        productName: productName,
        barcode: barcode,
        productImage: productImage,
        sellingPrice: sellingPrice,
      );
      _groceries.add(grocery);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error creating product: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct({
    required GroceryWithDetails grocery,
    required String productName,
    required String barcode,
    String? productImage,
    required double sellingPrice,
    required bool isActive,
  }) async {
    try {
      await _repository.updateProduct(
        productId: grocery.product.id,
        productName: productName,
        barcode: barcode,
        productImage: productImage,
        sellingPrice: sellingPrice,
        isActive: isActive,
      );

      // Reload to get fresh data
      await loadGroceries(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating product: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleProductStatus(GroceryWithDetails grocery) async {
    try {
      final newStatus = !grocery.product.isActive;
      await _repository.toggleProductStatus(grocery.product.id, newStatus);
      await loadGroceries(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error toggling status: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(GroceryWithDetails grocery) async {
    try {
      await _repository.delete(grocery.grocery.id);
      await loadGroceries(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting product: $e');
      notifyListeners();
      return false;
    }
  }

  // ─── Batch Operations ─────────────────────────────────────────────────

  Future<bool> addBatch({
    required GroceryWithDetails grocery,
    required double capitalPrice,
    required int quantity,
    required DateTime purchaseDate,
    required DateTime expirationDate,
  }) async {
    try {
      final batch = await _repository.addBatch(
        productId: grocery.product.id,
        capitalPrice: capitalPrice,
        quantity: quantity,
        purchaseDate: purchaseDate,
        expirationDate: expirationDate,
      );

      final index = _groceries.indexWhere(
        (g) => g.grocery.id == grocery.grocery.id,
      );
      if (index != -1) {
        _groceries[index].batches.add(batch);
      } else {
        grocery.batches.add(batch);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding batch: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBatch({
    required GroceryWithDetails grocery,
    required GroceryBatchModel batch,
  }) async {
    try {
      await _repository.deleteBatch(batch.id);

      final index = _groceries.indexWhere(
        (g) => g.grocery.id == grocery.grocery.id,
      );
      if (index != -1) {
        _groceries[index].batches.removeWhere((b) => b.id == batch.id);
      } else {
        grocery.batches.removeWhere((b) => b.id == batch.id);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting batch: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBatch({
    required GroceryWithDetails grocery,
    required GroceryBatchModel batch,
    required double capitalPrice,
    required int quantity,
    required DateTime purchaseDate,
    required DateTime expirationDate,
  }) async {
    try {
      await _repository.updateBatch(
        batchId: batch.id,
        capitalPrice: capitalPrice,
        originalQuantity: quantity,
        remainingQuantity: quantity, 
        purchaseDate: purchaseDate,
        expirationDate: expirationDate,
      );

      await loadGroceries(forceRefresh: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating batch: $e');
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _isInitialized = false;
    _groceries = [];
    _state = GroceryState.idle;
    notifyListeners();
  }
}
