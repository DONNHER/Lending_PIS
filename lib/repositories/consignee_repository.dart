import '../models/consignee_model.dart';
import '../services/api_service.dart';

class ConsigneeRepository {
  final ApiService _api;

  const ConsigneeRepository(this._api);

  Future<List<ConsigneeModel>> getAll() async {
    try {
      final response = await _api.get('consignees');
      final List<dynamic> data = response is List ? response : (response['data'] ?? []);
      return data.map((json) => ConsigneeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch consignees: $e');
    }
  }

  Future<List<ConsigneeModel>> search(String query) async {
    try {
      final response = await _api.get('consignees/search', queryParams: {'query': query});
      final List<dynamic> data = response is List ? response : (response['data'] ?? []);
      return data.map((json) => ConsigneeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  Future<ConsigneeModel> add(ConsigneeModel consignee) async {
    try {
      final response = await _api.post('consignees', body: consignee.toJson());
      final data = response is Map ? (response['data'] ?? response) : response;
      return ConsigneeModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to add consignee: $e');
    }
  }

  Future<ConsigneeModel> update(ConsigneeModel consignee) async {
    try {
      final response = await _api.put('consignees/${consignee.id}', body: consignee.toJson());
      final data = response is Map ? (response['data'] ?? response) : response;
      return ConsigneeModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update consignee: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.delete('consignees/$id');
    } catch (e) {
      throw Exception('Failed to delete consignee: $e');
    }
  }

  Future<ConsigneeModel> getById(String id) async {
    try {
      final response = await _api.get('consignees/$id');
      final data = response is Map ? (response['data'] ?? response) : response;
      return ConsigneeModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch consignee: $e');
    }
  }
}
