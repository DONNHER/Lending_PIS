import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductRepository {
  final ApiService _api;

  const ProductRepository(this._api);

  Future<List<ProductModel>> getAll() async {
    try {
      final response = await _api.get('products');
      final List<dynamic> data = response['data'];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<ProductModel> getById(String id) async {
    try {
      final response = await _api.get('products/$id');
      return ProductModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  Future<ProductModel> create(ProductModel product) async {
    try {
      final response = await _api.post('products', body: product.toJson());
      return ProductModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<ProductModel> update(ProductModel product) async {
    try {
      final response = await _api.put('products/${product.id}', body: product.toJson());
      return ProductModel.fromJson(response['data']);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('products/$id');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
