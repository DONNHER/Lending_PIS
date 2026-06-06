import '../models/consignment_daily_inventory.dart';
import '../services/api_service.dart';

class DailyInventoryRepository {
  final ApiService _api;

  const DailyInventoryRepository(this._api);

  Future<List<ConsignmentDailyInventoryModel>> getByProductId(String productId) async {
    try {
      final response = await _api.get('inventory/product/$productId');
      final List<dynamic> data = response['data'];
      return data.map((json) => ConsignmentDailyInventoryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch inventory records: $e');
    }
  }

  Future<void> add({
    required String productId,
    required DateTime consignmentDate,
    required int quantityReceived,
    required int quantitySold,
  }) async {
    try {
      await _api.post('inventory', body: {
        'product_id': productId,
        'inventory_date': consignmentDate.toIso8601String().split('T')[0],
        'quantity_received': quantityReceived,
        'quantity_sold': quantitySold,
      });
    } catch (e) {
      throw Exception('Failed to add inventory: $e');
    }
  }

  Future<void> update({
    required String id,
    required int quantityReceived,
    required int quantitySold,
    required DateTime consignmentDate,
  }) async {
    try {
      await _api.put('inventory/$id', body: {
        'quantity_received': quantityReceived,
        'quantity_sold': quantitySold,
        'inventory_date': consignmentDate.toIso8601String().split('T')[0],
      });
    } catch (e) {
      throw Exception('Failed to update inventory: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('inventory/$id');
    } catch (e) {
      throw Exception('Failed to delete inventory: $e');
    }
  }
}
