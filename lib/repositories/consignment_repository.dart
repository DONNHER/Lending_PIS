import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consignment_model.dart';

/// Handles all database operations for consignments (product-consignee links)
class ConsignmentRepository {
  final SupabaseClient _client;
  static const String _tableName = 'consignments';

  const ConsignmentRepository(this._client);

  /// Get all consigned products for a specific consignee
  /// Joins with products table to get product details
  Future<List<Map<String, dynamic>>> getConsignmentsWithProducts(String consigneeId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*, products(*)') // Join with products table
          .eq('consignee_id', consigneeId)
          .order('id', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch consignments: ${e.message}');
    }
  }

  /// Add a new consignment (link product to consignee)
  Future<ConsignmentModel> add({
    required String productId,
    required String consigneeId,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert({
            'product_id': productId,
            'consignee_id': consigneeId,
            'commission_rate': commissionRate,
            'capital_price': capitalPrice,
          })
          .select()
          .single();

      return ConsignmentModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to add consignment: ${e.message}');
    }
  }

  /// Update an existing consignment
  Future<ConsignmentModel> update({
    required int id,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .update({
            'commission_rate': commissionRate,
            'capital_price': capitalPrice,
          })
          .eq('id', id)
          .select()
          .single();

      return ConsignmentModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update consignment: ${e.message}');
    }
  }

  /// Delete a consignment by ID
  Future<void> delete(int id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete consignment: ${e.message}');
    }
  }

  /// Check if a product is already consigned to this consignee
  Future<bool> isProductAlreadyConsigned({
    required String productId,
    required String consigneeId,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('product_id', productId)
          .eq('consignee_id', consigneeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}