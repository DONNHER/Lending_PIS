import 'package:flutter/foundation.dart';
import '../models/shareholder_model.dart';
import '../services/api_service.dart';
import '../utils/parsers.dart';

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
      // 🚀 Silent: "Not Found" is expected when checking email availability
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
      debugPrint('Error in getShareholderByUserId: $e');
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

  List<ShareholderModel> _extractList(dynamic response) {
    if (response == null || response['success'] != true) return [];
    final dynamic rawData = response['data'];
    List<dynamic> items = [];
    if (rawData is List) {
      items = rawData;
    } else if (rawData is Map && rawData['data'] is List) {
      items = rawData['data'];
    } else if (response['users'] != null && response['users']['data'] is List) {
      items = response['users']['data'];
    }
    return items.map((json) => ShareholderModel.fromJson(json as Map<String, dynamic>)).toList();
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
      if (sortBy != null) {
        if (sortBy == 'Name') {
          queryParams['sort_by'] = 'first_name';
        } else if (sortBy == 'Amount') {
          queryParams['sort_by'] = 'total_share_capital';
        } else {
          queryParams['sort_by'] = sortBy;
        }
      }
      final response = await _api.get('/shareholders', queryParams: queryParams);
      return _extractList(response);
    } catch (e) {
      debugPrint('Error in getShareholders: $e');
    }
    return [];
  }

  Future<List<ShareholderModel>> getUsers({
    int offset = 0,
    int limit = 10,
    String? sortBy,
    String? role,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
      };
      if (sortBy != null) {
        if (sortBy == 'Name') {
          queryParams['sort_by'] = 'firstname';
        } else if (sortBy == 'Amount') {
          queryParams['sort_by'] = 'id'; 
        } else {
          queryParams['sort_by'] = sortBy;
        }
      }
      if (role != null && role != 'All') queryParams['role'] = role.toLowerCase();
      final response = await _api.get('/admin/users', queryParams: queryParams);
      return _extractList(response);
    } catch (e) {
      debugPrint('Error in getUsers: $e');
    }
    return [];
  }

  Future<int> getShareholdersCount({String? role}) async {
    try {
      final Map<String, String> queryParams = {};
      if (role != null && role != 'All') queryParams['role'] = role.toLowerCase();
      final endpoint = (role == 'Shareholder') ? '/shareholders/count' : '/admin/users/count';
      final response = await _api.get(endpoint, queryParams: queryParams);
      if (response != null && response['success'] == true) {
        return Parsers.parseInt(response['count'] ?? response['total'] ?? response['meta']?['total']);
      }
    } catch (e) {
      debugPrint('Error getting count: $e');
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
      debugPrint('Error in getShareholderById: $e');
    }
    return null;
  }

  Future<ShareholderModel?> getUserById(String userId) async {
    try {
      final response = await _api.get('/admin/users/$userId');
      if (response != null && response['success'] == true) {
        return ShareholderModel.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error in getUserById: $e');
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
}
