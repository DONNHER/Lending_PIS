import 'package:flutter/foundation.dart';
import '../models/shareholder_model.dart';
import '../services/api_service.dart';

class ShareholderRepository {
  final ApiService _api;

  const ShareholderRepository(this._api);

  Future<ShareholderModel?> getShareholderByEmail(String email) async {
    try {
      final response = await _api.get('/shareholders/email/$email');
      if (response != null && response['success'] == true) {
        return ShareholderModel.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error getting shareholder by email: $e');
    }
    return null;
  }

  Future<ShareholderModel?> getShareholderByUserId(String authUuid) async {
    try {
      final response = await _api.get('/shareholders/user/$authUuid');
      if (response != null && response['success'] == true) {
        return ShareholderModel.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('ShareholderRepo ERROR: $e');
    }
    return null;
  }

  Future<void> addShareholder(Map<String, dynamic> data) async {
    try {
      await _api.post('/shareholders', body: data);
    } catch (e) {
      throw Exception('Failed to add shareholder: $e');
    }
  }

  Future<List<ShareholderModel>> getShareholders({
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

      final response = await _api.get('/shareholders', queryParams: queryParams);
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data']['data'] ?? [];
        return data.map((json) => ShareholderModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error in getShareholders: $e');
    }
    return [];
  }

  Future<int> getShareholdersCount() async {
    try {
      final response = await _api.get('/shareholders/count');
      if (response != null && response['success'] == true) {
        return response['count'];
      }
    } catch (e) {
      debugPrint('Error getting shareholders count: $e');
    }
    return 0;
  }

  Future<ShareholderModel?> getShareholderById(String id) async {
    try {
      final response = await _api.get('/shareholders/$id');
      if (response != null && response['success'] == true) {
        return ShareholderModel.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error getting shareholder by ID: $e');
    }
    return null;
  }

  Future<void> deleteShareholder(String id) async {
    await _api.delete('/shareholders/$id');
  }

  Future<void> updateShareCapital(String id, double newTotalCapital) async {
    try {
      await _api.put('/shareholders/$id/capital', body: {
        'total_share_capital': newTotalCapital,
      });
    } catch (e) {
      throw Exception('Failed to update share capital: $e');
    }
  }

  Future<void> seedShareholders() async {
    debugPrint('seedShareholders called - should be handled by Laravel seeders.');
  }
}
