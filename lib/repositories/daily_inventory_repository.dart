import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/consignment_daily_inventory.dart';

class DailyInventoryRepository {
  final SupabaseClient _client;
  static const String _tableName = 'consignment_daily_inventory';

  const DailyInventoryRepository(this._client);

  // ✅ FIX: DB has no consignment_id column — filter by product_id instead.
  //    The old getByConsignmentId() was querying a non-existent column and
  //    always returned an empty list.
  Future<List<ConsignmentDailyInventoryModel>> getByProductId(
      String productId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('product_id', productId)
          // ✅ FIX: actual column name is 'consingment_date' (typo is in DB)
          .order('consingment_date', ascending: false);

      return (response as List)
          .map((json) => ConsignmentDailyInventoryModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch inventory records: ${e.message}');
    }
  }

  Future<void> add({
    required String productId,
    required DateTime consignmentDate,
    required int quantityReceived,
    required int quantitySold,
  }) async {
    try {
      await _client.from(_tableName).insert({
        'product_id': productId,
        // ✅ FIX: column name in DB is 'consingment_date' (typo is in DB)
        'consingment_date': consignmentDate.toIso8601String().split('T')[0],
        'quantity_received': quantityReceived,
        'quantity_sold': quantitySold,
        // ✅ FIX: removed 'consignment_id' — column does not exist in DB
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to add inventory: ${e.message}');
    }
  }

  Future<void> update({
    required String id,
    required int quantityReceived,
    required int quantitySold,
    required DateTime consignmentDate,
  }) async {
    try {
      await _client
          .from(_tableName)
          .update({
            'quantity_received': quantityReceived,
            'quantity_sold': quantitySold,
            // ✅ FIX: column name in DB is 'consingment_date' (typo is in DB)
            'consingment_date':
                consignmentDate.toIso8601String().split('T')[0],
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update inventory: ${e.message}');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete inventory: ${e.message}');
    }
  }
}