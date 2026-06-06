import '../models/consignment_model.dart';
import '../services/api_service.dart';

/// Handles all database operations for consignments (product-consignee links) via Laravel API
class ConsignmentRepository {
  final ApiService _api;

  const ConsignmentRepository(this._api);

  /// Get all consigned products for a specific consignee
  /// Joins with products table to get product details
  Future<List<Map<String, dynamic>>> getConsignmentsWithProducts(String consigneeId) async {
    try {
      final response = await _api.get('consignees/$consigneeId/products');
      return (response['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch consignments: $e');
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
      final response = await _api.post('consignments', body: {
        'product_id': productId,
        'consignee_id': consigneeId,
        'commission_rate': commissionRate,
        'capital_price': capitalPrice,
      });

      return ConsignmentModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to add consignment: $e');
    }
  }

  /// Update an existing consignment
  Future<ConsignmentModel> update({
    required int id,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    try {
      final response = await _api.put('consignments/$id', body: {
        'commission_rate': commissionRate,
        'capital_price': capitalPrice,
      });

      return ConsignmentModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to update consignment: $e');
    }
  }

  /// Delete a consignment by ID
  Future<void> delete(int id) async {
    try {
      await _api.delete('consignments/$id');
    } catch (e) {
      throw Exception('Failed to delete consignment: $e');
    }
  }

  /// Check if a product is already consigned to this consignee
  Future<bool> isProductAlreadyConsigned({
    required String productId,
    required String consigneeId,
  }) async {
    try {
      final response = await _api.get('consignments/check', queryParams: {
        'product_id': productId,
        'consignee_id': consigneeId,
      });

      return response['exists'] as bool;
    } catch (e) {
      return false;
    }
  }
}
