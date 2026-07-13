import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/models/transaction_model.dart';

class TransactionRepository {
  final ApiService _apiService;

  TransactionRepository(this._apiService);

  Future<List<TransactionModel>> getTransactionsByShareholderId(String shareholderId) async {
    if (shareholderId.isEmpty) return [];
    final response = await _apiService.get('/transactions/shareholder/$shareholderId');
    final List data = response['data'] ?? [];
    return data.map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getPaginatedTransactions({int page = 1, int perPage = 10, String? search}) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    final response = await _apiService.get('/transactions', queryParams: queryParams);
    final List dataList = response['data'] ?? [];
    
    return {
      'transactions': dataList.map((e) => TransactionModel.fromJson(e)).toList(),
      'total': response['meta']?['total'] ?? dataList.length,
      'last_page': response['meta']?['last_page'] ?? 1,
      'current_page': response['meta']?['current_page'] ?? page,
    };
  }

  Future<List<TransactionModel>> getTransactions() async {
    final response = await _apiService.get('/transactions');
    final List data = response['data'] ?? [];
    return data.map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final response = await _apiService.get('/transactions/$id');
    if (response != null && response['data'] != null) {
      return TransactionModel.fromJson(response['data']);
    }
    return null;
  }

  Future<List<TransactionModel>> getTransactionsByReferenceId(String refId) async {
    final response = await _apiService.get('/transactions/reference/$refId');
    final List data = response['data'] ?? [];
    return data.map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<TransactionModel?> createTransaction({
    required String shareholderId,
    required double amount,
    required String type,
    required String status,
    required String referenceId,
    String method = 'Cash',
    String? description,
  }) async {
    final response = await _apiService.post('/transactions', body: {
      'shareholder_id': shareholderId,
      'amount': amount,
      'type': type,
      'status': status,
      'reference_id': referenceId,
      'method': method,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    });
    if (response != null && response['data'] != null) {
      return TransactionModel.fromJson(response['data']);
    }
    return null;
  }
}
