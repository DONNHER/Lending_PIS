import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consignment_model.dart';
import '../models/product_model.dart';
import '../models/consignee_model.dart';

class ConsignmentWithDetails {
  final ConsignmentModel consignment;
  final ProductModel product;
  final ConsigneeModel? consignee;

  const ConsignmentWithDetails({
    required this.consignment,
    required this.product,
    this.consignee,
  });
}

class ConsignmentProductsRepository {
  final SupabaseClient _client;

  const ConsignmentProductsRepository(this._client);

  // ─── Fetch ────────────────────────────────────────────────────────────

  Future<List<ConsignmentWithDetails>> getAll() async {
    try {
      final response = await _client
          .from('consignments')
          .select('*, products(*), consignees(*)')
          .order('id', ascending: false);

      return (response as List).map((json) {
        return ConsignmentWithDetails(
          consignment: ConsignmentModel.fromJson(json),
          product: ProductModel.fromJson(json['products']),
          consignee: json['consignees'] != null
              ? ConsigneeModel.fromJson(json['consignees'])
              : null,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch consignments: ${e.message}');
    }
  }

  Future<List<ConsignmentWithDetails>> search(String query) async {
    try {
      final response = await _client
          .from('consignments')
          .select('*, products(*), consignees(*)')
          .or('products.product_name.ilike.%$query%,products.barcode.ilike.%$query%,consignees.full_name.ilike.%$query%')
          .order('id', ascending: false);

      return (response as List).map((json) {
        return ConsignmentWithDetails(
          consignment: ConsignmentModel.fromJson(json),
          product: ProductModel.fromJson(json['products']),
          consignee: json['consignees'] != null
              ? ConsigneeModel.fromJson(json['consignees'])
              : null,
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Search failed: ${e.message}');
    }
  }

  // ─── Create Product + Consignment (Transaction) ───────────────────────

  /// Creates a new product AND links it to a consignee
  /// Returns the created consignment with joined details
  Future<ConsignmentWithDetails> createProductWithConsignment({
    required String productName,
    required String barcode,
    String? productImage,
    required double sellingPrice,
    required String consigneeId,
    required double commissionRate,
    required double capitalPrice,
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

      final productId = productResponse['id'] as String;

      // Step 2: Create the consignment link
      final consignmentResponse = await _client
          .from('consignments')
          .insert({
            'product_id': productId,
            'consignee_id': consigneeId,
            'commission_rate': commissionRate,
            'capital_price': capitalPrice,
          })
          .select('*, products(*), consignees(*)')
          .single();

      return ConsignmentWithDetails(
        consignment: ConsignmentModel.fromJson(consignmentResponse),
        product: ProductModel.fromJson(consignmentResponse['products']),
        consignee: consignmentResponse['consignees'] != null
            ? ConsigneeModel.fromJson(consignmentResponse['consignees'])
            : null,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to create consignment: ${e.message}');
    }
  }

  // ─── Update Consignment ───────────────────────────────────────────────

  Future<void> update({
    required int id,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    try {
      await _client
          .from('consignments')
          .update({
            'commission_rate': commissionRate,
            'capital_price': capitalPrice,
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update consignment: ${e.message}');
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

  // ─── Delete ───────────────────────────────────────────────────────────

  Future<void> delete(int id) async {
    try {
      // First get the product_id from this consignment
      final consignment = await _client
          .from('consignments')
          .select('product_id')
          .eq('id', id)
          .single();

      final productId = consignment['product_id'] as String;

      // Delete the consignment (product will be cascade deleted due to FK constraint)
      await _client.from('consignments').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete consignment: ${e.message}');
    }
  }
}