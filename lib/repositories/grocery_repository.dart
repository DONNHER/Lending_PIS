import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grocery_model.dart';
import '../models/grocery_batch_model.dart';
import '../models/product_model.dart';

class GroceryWithDetails {
  final GroceryModel grocery;
  final ProductModel product;
  // ✅ FIX: was `final List<GroceryBatchModel> batches` initialised with
  //    `const []` (an *unmodifiable* list).  Calling `.addAll()` on it threw
  //    an Unsupported operation at runtime and silently left batches empty.
  //    Changed to a plain growable list so the repository can populate it.
  final List<GroceryBatchModel> batches;

  GroceryWithDetails({
    required this.grocery,
    required this.product,
    List<GroceryBatchModel>? batches,
  }) : batches = batches ?? [];
}

class GroceryRepository {
  final SupabaseClient _client;

  static const String _groceriesTable = 'groceries';
  static const String _groceryBatchesTable = 'grocery_batches';

  const GroceryRepository(this._client);

  // ─── Fetch All Grocery Products ───────────────────────────────────────

  Future<List<GroceryWithDetails>> getAll() async {
    try {
      final response = await _client
          .from(_groceriesTable)
          .select('*, products(*)')
          .order('id', ascending: false);

      final groceries = await Future.wait(
        (response as List).map((json) async {
          final grocery = GroceryModel.fromJson(json);
          final product = ProductModel.fromJson(json['products']);
          // ✅ FIX: batches are stored with the products-table ID, not the
          //    groceries-table ID. Must pass product.id here.
          final batches = await getBatches(product.id);
          return GroceryWithDetails(
            grocery: grocery,
            product: product,
            batches: batches,
          );
        }),
      );

      return groceries;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch grocery products: ${e.message}');
    }
  }

  // ─── Search ───────────────────────────────────────────────────────────

  Future<List<GroceryWithDetails>> search(String query) async {
    try {
      final response = await _client
          .from(_groceriesTable)
          .select('*, products(*)')
          .or(
            'products.product_name.ilike.%$query%,products.barcode.ilike.%$query%',
          )
          .order('id', ascending: false);

      final groceries = await Future.wait(
        (response as List).map((json) async {
          final grocery = GroceryModel.fromJson(json);
          final product = ProductModel.fromJson(json['products']);
          // ✅ FIX: same as getAll — use product.id not grocery.id
          final batches = await getBatches(product.id);
          return GroceryWithDetails(
            grocery: grocery,
            product: product,
            batches: batches,
          );
        }),
      );

      return groceries;
    } on PostgrestException catch (e) {
      throw Exception('Search failed: ${e.message}');
    }
  }

  // ─── Get Batches ──────────────────────────────────────────────────────

  Future<List<GroceryBatchModel>> getBatches(String groceryId) async {
    try {
      final response = await _client
          .from(_groceryBatchesTable)
          .select()
          .eq('product_id', groceryId)
          .order('purchase_date', ascending: false);

      return (response as List)
          .map((json) => GroceryBatchModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch batches: ${e.message}');
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
      // Step 1: Create the product
      final productResponse = await _client
          .from('products')
          .insert({
            'product_name': productName,
            'barcode': barcode,
            'product_image': productImage,
            'is_active': true,
            'selling_price': sellingPrice,
          })
          .select()
          .single();

      final product = ProductModel.fromJson(productResponse);

      // Step 2: Create the grocery link
      final groceryResponse = await _client
          .from(_groceriesTable)
          .insert({'product_id': product.id})
          .select()
          .single();

      final grocery = GroceryModel.fromJson(groceryResponse);

      return GroceryWithDetails(
        grocery: grocery,
        product: product,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to create grocery product: ${e.message}');
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
      await _client
          .from('products')
          .update({
            'product_name': productName,
            'barcode': barcode,
            'product_image': productImage,
            'selling_price': sellingPrice,
            'is_active': isActive,
          })
          .eq('id', productId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update product: ${e.message}');
    }
  }

  // ─── Toggle Product Status ────────────────────────────────────────────

  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _client
          .from('products')
          .update({'is_active': isActive})
          .eq('id', productId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update status: ${e.message}');
    }
  }

  // ─── Delete Grocery Product ───────────────────────────────────────────

  Future<void> delete(String groceryId) async {
    try {
      await _client.from(_groceriesTable).delete().eq('id', groceryId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete grocery product: ${e.message}');
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
      final response = await _client
          .from(_groceryBatchesTable)
          .insert({
            'product_id': productId,
            'capital_price': capitalPrice,
            'original_quantity': quantity,
            'remaining_quantity': quantity,
            'purchase_date': purchaseDate.toIso8601String().split('T')[0],
            'expiration_date': expirationDate.toIso8601String().split('T')[0],
          })
          .select()
          .single();

      return GroceryBatchModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to add batch: ${e.message}');
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
      await _client
          .from(_groceryBatchesTable)
          .update({
            'capital_price': capitalPrice,
            'original_quantity': originalQuantity,
            'remaining_quantity': remainingQuantity,
            'purchase_date': purchaseDate.toIso8601String().split('T')[0],
            'expiration_date': expirationDate.toIso8601String().split('T')[0],
          })
          .eq('id', batchId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update batch: ${e.message}');
    }
  }

  Future<void> deleteBatch(String batchId) async {
    try {
      await _client.from(_groceryBatchesTable).delete().eq('id', batchId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete batch: ${e.message}');
    }
  }
}