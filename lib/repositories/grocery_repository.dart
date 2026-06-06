import '../models/grocery_model.dart';
import '../models/grocery_batch_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class GroceryWithDetails {
  final GroceryModel grocery;
  final ProductModel product;
  final List<GroceryBatchModel> batches;

  GroceryWithDetails({
    required this.grocery,
    required this.product,
    List<GroceryBatchModel>? batches,
  }) : batches = batches ?? [];
}

class GroceryRepository {
  final ApiService _api;

  const GroceryRepository(this._api);

  // ─── Fetch All Grocery Products ───────────────────────────────────────

  Future<List<GroceryWithDetails>> getAll() async {
    try {
      final response = await _api.get('groceries');
      final List<dynamic> data = response['data'];

      return data.map((json) {
        return GroceryWithDetails(
          grocery: GroceryModel.fromJson(json),
          product: ProductModel.fromJson(json['product']),
          batches: (json['batches'] as List?)
                  ?.map((b) => GroceryBatchModel.fromJson(b))
                  .toList() ??
              [],
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch grocery products: $e');
    }
  }

  // ─── Search ───────────────────────────────────────────────────────────

  Future<List<GroceryWithDetails>> search(String query) async {
    try {
      final response = await _api.get('groceries/search', queryParams: {'query': query});
      final List<dynamic> data = response['data'];

      return data.map((json) {
        return GroceryWithDetails(
          grocery: GroceryModel.fromJson(json),
          product: ProductModel.fromJson(json['product']),
          batches: (json['batches'] as List?)
                  ?.map((b) => GroceryBatchModel.fromJson(b))
                  .toList() ??
              [],
        );
      }).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // ─── Get Batches ──────────────────────────────────────────────────────

  Future<List<GroceryBatchModel>> getBatches(String productId) async {
    try {
      final response = await _api.get('products/$productId/batches');
      final List<dynamic> data = response['data'];
      return data.map((json) => GroceryBatchModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch batches: $e');
    }
  }

  // ─── Create Grocery Product ───────────────────────────────────────────

  Future<GroceryWithDetails> createProduct({
    required String productName,
    required String barcode,
    String? productImage,
    required double sellingPrice,
  }) async {
    try {
      final response = await _api.post('groceries', body: {
        'product_name': productName,
        'barcode': barcode,
        'product_image': productImage,
        'selling_price': sellingPrice,
      });

      final json = response['data'];
      return GroceryWithDetails(
        grocery: GroceryModel.fromJson(json),
        product: ProductModel.fromJson(json['product']),
      );
    } catch (e) {
      throw Exception('Failed to create grocery product: $e');
    }
  }

  Future<void> updateProduct({
    required String productId,
    required String productName,
    required String barcode,
    String? productImage,
    required double sellingPrice,
    required bool isActive,
  }) async {
    try {
      await _api.put('products/$productId', body: {
        'product_name': productName,
        'barcode': barcode,
        'product_image': productImage,
        'selling_price': sellingPrice,
        'is_active': isActive,
      });
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // ─── Toggle Product Status ────────────────────────────────────────────

  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _api.put('products/$productId/status', body: {'is_active': isActive});
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // ─── Delete Grocery Product ───────────────────────────────────────────

  Future<void> delete(String groceryId) async {
    try {
      await _api.delete('groceries/$groceryId');
    } catch (e) {
      throw Exception('Failed to delete grocery product: $e');
    }
  }

  // ─── Batch Operations ─────────────────────────────────────────────────

  Future<GroceryBatchModel> addBatch({
    required String productId,
    required double capitalPrice,
    required int quantity,
    required DateTime purchaseDate,
    required DateTime expirationDate,
  }) async {
    try {
      final response = await _api.post('batches', body: {
        'product_id': productId,
        'capital_price': capitalPrice,
        'original_quantity': quantity,
        'remaining_quantity': quantity,
        'purchase_date': purchaseDate.toIso8601String().split('T')[0],
        'expiration_date': expirationDate.toIso8601String().split('T')[0],
      });

      return GroceryBatchModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to add batch: $e');
    }
  }

  Future<void> updateBatch({
    required String batchId,
    required double capitalPrice,
    required int originalQuantity,
    required int remainingQuantity,
    required DateTime purchaseDate,
    required DateTime expirationDate,
  }) async {
    try {
      await _api.put('batches/$batchId', body: {
        'capital_price': capitalPrice,
        'original_quantity': originalQuantity,
        'remaining_quantity': remainingQuantity,
        'purchase_date': purchaseDate.toIso8601String().split('T')[0],
        'expiration_date': expirationDate.toIso8601String().split('T')[0],
      });
    } catch (e) {
      throw Exception('Failed to update batch: $e');
    }
  }

  Future<void> deleteBatch(String batchId) async {
    try {
      await _api.delete('batches/$batchId');
    } catch (e) {
      throw Exception('Failed to delete batch: $e');
    }
  }
}
