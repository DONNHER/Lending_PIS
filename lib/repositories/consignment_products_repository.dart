import '../models/consignment_model.dart';
import '../models/product_model.dart';
import '../models/consignee_model.dart';
import '../services/api_service.dart';

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
  final ApiService _api;

  const ConsignmentProductsRepository(this._api);

  // ─── Fetch ────────────────────────────────────────────────────────────

  Future<List<ConsignmentWithDetails>> getAll() async {
    try {
      final response = await _api.get('consignment-products');
      final List<dynamic> data = response['data'];

      return data.map((json) {
        return ConsignmentWithDetails(
          consignment: ConsignmentModel.fromJson(json),
          product: ProductModel.fromJson(json['product']),
          consignee: json['consignee'] != null
              ? ConsigneeModel.fromJson(json['consignee'])
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch consignments: $e');
    }
  }

  Future<List<ConsignmentWithDetails>> search(String query) async {
    try {
      final response = await _api.get('consignment-products/search', queryParams: {'query': query});
      final List<dynamic> data = response['data'];

      return data.map((json) {
        return ConsignmentWithDetails(
          consignment: ConsignmentModel.fromJson(json),
          product: ProductModel.fromJson(json['product']),
          consignee: json['consignee'] != null
              ? ConsigneeModel.fromJson(json['consignee'])
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // ─── Create Product + Consignment (Transaction) ───────────────────────

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
      final response = await _api.post('consignment-products', body: {
        'product_name': productName,
        'barcode': barcode,
        'product_image': productImage,
        'selling_price': sellingPrice,
        'consignee_id': consigneeId,
        'commission_rate': commissionRate,
        'capital_price': capitalPrice,
      });

      final json = response['data'];
      return ConsignmentWithDetails(
        consignment: ConsignmentModel.fromJson(json),
        product: ProductModel.fromJson(json['product']),
        consignee: json['consignee'] != null
            ? ConsigneeModel.fromJson(json['consignee'])
            : null,
      );
    } catch (e) {
      throw Exception('Failed to create consignment: $e');
    }
  }

  // ─── Update Consignment ───────────────────────────────────────────────

  Future<void> update({
    required int id,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    try {
      await _api.put('consignment-products/$id', body: {
        'commission_rate': commissionRate,
        'capital_price': capitalPrice,
      });
    } catch (e) {
      throw Exception('Failed to update consignment: $e');
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

  // ─── Delete ───────────────────────────────────────────────────────────

  Future<void> delete(int id) async {
    try {
      await _api.delete('consignment-products/$id');
    } catch (e) {
      throw Exception('Failed to delete consignment: $e');
    }
  }
}
