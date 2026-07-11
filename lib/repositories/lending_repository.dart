import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/models/transaction_model.dart';

class LendingRepository {
  final ApiService _apiService;

  LendingRepository(this._apiService);

  Future<List<LoanRequestModel>> getLoanRequestsByShareholderId(String shareholderId) async {
    final response = await _apiService.get('/loan-requests', queryParams: {'shareholder_id': shareholderId});
    final List data = response['data'] ?? [];
    return data.map((e) => LoanRequestModel.fromJson(e)).toList();
  }

  Future<List<LoanRequestModel>> getLoanRequestsByComakerId(String comakerId) async {
    final response = await _apiService.get('/loan-requests', queryParams: {'comaker_id': comakerId});
    final List data = response['data'] ?? [];
    return data.map((e) => LoanRequestModel.fromJson(e)).toList();
  }

  Future<List<LoanRequestModel>> getLoanRequests() async {
    final response = await _apiService.get('/loans/requests');
    final List data = response['data'] ?? [];
    return data.map((e) => LoanRequestModel.fromJson(e)).toList();
  }

  Future<LoanRequestModel?> getLoanRequestById(String id) async {
    final response = await _apiService.get('/loans/requests/$id');
    if (response != null && response['data'] != null) {
      return LoanRequestModel.fromJson(response['data']);
    }
    return null;
  }

  Future<LoanModel?> getLoanById(String id) async {
    final response = await _apiService.get('/loans/$id');
    if (response != null && response['data'] != null) {
      return LoanModel.fromJson(response['data']);
    }
    return null;
  }

  Future<LoanModel?> getLoanByLoanRequestId(String requestId) async {
    final response = await _apiService.get('/loans/by-request/$requestId');
    if (response != null && response['data'] != null) {
      return LoanModel.fromJson(response['data']);
    }
    return null;
  }

  Future<LoanModel?> disburse(String loanRequestId) async {
    final response = await _apiService.post('/loan-requests/$loanRequestId/disburse');
    if (response != null && response['data'] != null) {
      return LoanModel.fromJson(response['data']);
    }
    return null;
  }

  Future<void> setComakerDecision({
    required String loanRequestId,
    required String comakerShareholderId,
    required ComakerStatus status,
  }) async {
    await _apiService.post('/loans/requests/$loanRequestId/comaker-decision', body: {
      'shareholder_id': comakerShareholderId,
      'status': status.name,
    });
  }

  Future<void> submitLoanRequest(Map<String, dynamic> data) async {
    await _apiService.post('/loans/requests', body: data);
  }

  Future<void> updateLoanRequestStatus(String id, LoanStatus status) async {
    await _apiService.post('/loans/requests/$id/status', body: {
      'status': status.name,
    });
  }

  Future<TransactionModel?> recordPayment({
    required String loanId,
    required double amount,
    required String method,
  }) async {
    final response = await _apiService.post('/loans/$loanId/payments', body: {
      'amount': amount,
      'payment_method': method,
    });
    if (response != null && response['data'] != null) {
      return TransactionModel.fromJson(response['data']);
    }
    return null;
  }

  Future<List<TransactionModel>> getPaymentHistory(String loanId) async {
    final response = await _apiService.get('/loans/$loanId/payments');
    final List data = response['data'] ?? [];
    return data.map((e) => TransactionModel.fromJson(e)).toList();
  }
}
