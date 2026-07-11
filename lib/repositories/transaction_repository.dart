import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/models/transaction_model.dart';

class TransactionRepository {
  final ApiService _apiService;

  TransactionRepository(this._apiService);

  Future<List<TransactionModel>> getTransactionsByShareholderId(String shareholderId) async {
    final response = await _apiService.get('/transactions/shareholder/$shareholderId');
    final List data = response['data'] ?? [];
    return data.map((e) => TransactionModel.fromJson(e)).toList();
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
    required String userId,
    required double amount,
    required String type,
    required String status,
    required String referenceId,
  }) async {
    final response = await _apiService.post('/transactions', body: {
      'user_id': userId,
      'amount': amount,
      'type': type,
      'status': status,
      'reference_id': referenceId,
    });
    if (response != null && response['data'] != null) {
      return TransactionModel.fromJson(response['data']);
    }
    return null;
  }
}
