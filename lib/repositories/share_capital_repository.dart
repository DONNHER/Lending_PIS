import 'package:flutter/foundation.dart';
import '../models/share_capital_model.dart';
import '../services/api_service.dart';

class ShareCapitalRepository {
  final ApiService _api;

  const ShareCapitalRepository(this._api);

  Future<List<ShareCapitalModel>> getShareCapitals({
    int offset = 0,
    int limit = 10,
    String? sortBy,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
      };
      if (sortBy != null) queryParams['sort_by'] = sortBy;

      debugPrint('ShareCapitalRepo: Fetching capitals from Laravel (offset: $offset, limit: $limit)');

      final response = await _api.get('share-capitals', queryParams: queryParams);
      final List<dynamic> data = response['data'];

      return data.map((json) => ShareCapitalModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('ShareCapitalRepo ERROR: $e');
      return [];
    }
  }

  Future<int> getShareCapitalsCount() async {
    try {
      final response = await _api.get('share-capitals/count');
      return response['total'] as int? ?? 0;
    } catch (e) {
      debugPrint('ShareCapitalRepo ERROR (getCount): $e');
      return 0;
    }
  }

  Future<void> addShareCapital(ShareCapitalModel capital) async {
    try {
      await _api.post('share-capitals', body: capital.toJson());
    } catch (e) {
      throw Exception('Failed to add share capital: $e');
    }
  }

  Future<void> deleteShareCapital(String id) async {
    try {
      await _api.delete('share-capitals/$id');
    } catch (e) {
      throw Exception('Failed to delete share capital: $e');
    }
  }
}
