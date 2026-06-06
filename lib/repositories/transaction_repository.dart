import 'package:flutter/foundation.dart';
import '../models/lending_models.dart';
import '../services/api_service.dart';

class TransactionRepository {
  final ApiService _api;

  TransactionRepository(this._api);

  Future<List<TransactionModel>> getTransactions({
    int offset = 0,
    int limit = 10,
    String? sortBy,
    List<String>? typesIn,
    String? status,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
      };

      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (typesIn != null && typesIn.isNotEmpty) queryParams['types'] = typesIn.join(',');
      if (status != null && status != 'All') queryParams['status'] = status;

      final response = await _api.get('transactions', queryParams: queryParams);
      final List<dynamic> data = response['data'];
      
      return data.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  Future<int> getTransactionsCount({
    List<String>? typesIn,
    String? status,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (typesIn != null && typesIn.isNotEmpty) queryParams['types'] = typesIn.join(',');
      if (status != null && status != 'All') queryParams['status'] = status;

      final response = await _api.get('transactions/count', queryParams: queryParams);
      return response['total'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error getting transactions count: $e');
      return 0;
    }
  }

  Future<List<TransactionModel>> getTransactionsByShareholderId(String shareholderId) async {
    try {
      final response = await _api.get('transactions/shareholder/$shareholderId');
      final List<dynamic> data = response['data'];
      return data.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting transactions for shareholder: $e');
      return [];
    }
  }

  Future<List<TransactionModel>> getUserTransactions({
    required String shareholderId,
    int limit = 5,
    List<String>? typesIn,
  }) async {
    try {
      final Map<String, String> queryParams = {'limit': limit.toString()};
      if (typesIn != null && typesIn.isNotEmpty) queryParams['types'] = typesIn.join(',');

      final response = await _api.get('transactions/shareholder/$shareholderId', queryParams: queryParams);
      final List<dynamic> data = response['data'];
      return data.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting user transactions: $e');
      return [];
    }
  }

  Future<List<TransactionModel>> getTransactionsByReferenceId(String referenceId) async {
    try {
      final response = await _api.get('transactions/reference/$referenceId');
      final List<dynamic> data = response['data'];
      return data.map((json) => TransactionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting transactions by reference: $e');
      return [];
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _api.delete('transactions/$id');
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  Future<void> insertTransaction(Map<String, dynamic> data) async {
    try {
      await _api.post('transactions', body: data);
    } catch (e) {
      throw Exception('Failed to record transaction history: $e');
    }
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
