import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductRepository {
  final SupabaseClient _client;
  static const String _tableName = 'products';

  const ProductRepository(this._client);

  Future<List<ProductModel>> getAll() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('product_name', ascending: true);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch products: ${e.message}');
    }
  }
}
