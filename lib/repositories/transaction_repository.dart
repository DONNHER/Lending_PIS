import 'package:flutter/foundation.dart';
import '../models/lending_models.dart';
import '../services/api_service.dart';

class TransactionRepository {
  final ApiService _api;

  TransactionRepository(this._api);

  /// Fetches a paginated list of all transactions
  Future<List<TransactionModel>> getTransactions({
    int offset = 0,
    int limit = 10,
    String? sortBy,
    List<String>? typesIn,
    String? status,
  }) async {
    final int page = (offset ~/ limit) + 1;
    
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'per_page': limit.toString(),
      'sort_by': sortBy ?? 'date',
      'sort_order': 'desc',
    };

    if (typesIn != null && typesIn.isNotEmpty) queryParams['types'] = typesIn.join(',');
    if (status != null && status != 'All') queryParams['status'] = status;

    final response = await _api.get('transactions', queryParams: queryParams);
    
    if (response == null) return [];
    
    dynamic rawData = response['data'];
    List<dynamic> list = [];
    
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['data'] is List) {
      list = rawData['data'];
    } else if (response is List) {
      list = response;
    }

    return list.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<int> getTransactionsCount({
    List<String>? typesIn,
    String? status,
  }) async {
    final Map<String, String> queryParams = {};
    if (typesIn != null && typesIn.isNotEmpty) queryParams['types'] = typesIn.join(',');
    if (status != null && status != 'All') queryParams['status'] = status;

    final response = await _api.get('transactions/count', queryParams: queryParams);
    if (response == null) return 0;
    
    return response['total'] as int? ?? response['count'] as int? ?? 0;
  }

  Future<List<TransactionModel>> getTransactionsByShareholderId(String shareholderId) async {
    final response = await _api.get('transactions/shareholder/$shareholderId');
    if (response == null) return [];
    final List<dynamic> data = response is List ? response : (response['data'] ?? []);
    return data.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<TransactionModel>> getUserTransactions({
    required String shareholderId,
    int limit = 5,
    List<String>? typesIn,
  }) async {
    final Map<String, String> queryParams = {'limit': limit.toString()};
    if (typesIn != null && typesIn.isNotEmpty) queryParams['types'] = typesIn.join(',');

    final response = await _api.get('transactions/shareholder/$shareholderId', queryParams: queryParams);
    if (response == null) return [];
    
    final List<dynamic> data = response is List ? response : (response['data'] ?? []);
    return data.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// 🚀 STABLE FIX: Fetches history via Query Parameters to avoid 404 "Route not found" errors.
  Future<List<TransactionModel>> getTransactionsByReferenceId(String referenceId) async {
    // This will hit: /api/transactions?reference_id=...
    debugPrint('🚀 [TX_REPO] CALLING: /api/transactions?reference_id=$referenceId');
    
    final response = await _api.get('transactions', queryParams: {
      'reference_id': referenceId,
      'per_page': '100', 
    });
    
    if (response == null) return [];
    
    dynamic rawData = response['data'];
    List<dynamic> list = [];
    
    if (rawData is List) {
      list = rawData;
    } else if (rawData is Map && rawData['data'] is List) {
      list = rawData['data'];
    }
    
    return list.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> deleteTransaction(String id) async {
    await _api.delete('transactions/$id');
  }

  Future<void> insertTransaction(Map<String, dynamic> data) async {
    await _api.post('transactions', body: data);
  }

  Future<void> logActivity({
    required String action,
    required String details,
    required String shareholderId,
    String? ipAddress,
  }) async {
    try {
      await _api.post('activity-logs', body: {
        'shareholder_id': shareholderId,
        'action': action,
        'description': details,
        'ip_address': ipAddress,
      });
    } catch (e) {
      debugPrint('General error in logActivity: $e');
    }
  }
}
