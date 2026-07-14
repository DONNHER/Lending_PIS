import 'package:flutter/foundation.dart';
import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/models/transaction_model.dart';

class LendingRepository {
  final ApiService _apiService;

  LendingRepository(this._apiService);

  Future<List<LoanRequestModel>> getLoanRequestsByShareholderId(String shareholderId) async {
    if (shareholderId.isEmpty) return [];
    final response = await _apiService.get('/loan-requests', queryParams: {'shareholder_id': shareholderId});
    final List data = response['data'] ?? [];
    return data.map((e) => LoanRequestModel.fromJson(e)).toList();
  }

  Future<List<LoanRequestModel>> getLoanRequestsByComakerId(String comakerId) async {
    if (comakerId.isEmpty) return [];
    final response = await _apiService.get('/loan-requests', queryParams: {'comaker_id': comakerId});
    final List data = response['data'] ?? [];
    return data.map((e) => LoanRequestModel.fromJson(e)).toList();
  }

  Future<List<LoanRequestModel>> getLoanRequests() async {
    final response = await _apiService.get('/loan-requests');
    final List data = response['data'] ?? [];
    return data.map((e) => LoanRequestModel.fromJson(e)).toList();
  }

  Future<LoanRequestModel?> getLoanRequestById(String id) async {
    final response = await _apiService.get('/loan-requests/$id');
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
    await _apiService.post('/loan-requests/$loanRequestId/comaker-decision', body: {
      'shareholder_id': comakerShareholderId,
      'status': status.name,
    });
  }

  Future<void> submitLoanRequest(Map<String, dynamic> data) async {
    await _apiService.post('/loan-requests', body: data);
  }

  Future<void> updateLoanRequestStatus(String id, LoanStatus status) async {
    await _apiService.post('/loan-requests/$id/status', body: {
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
    if (loanId.isEmpty || loanId == 'null') {
      debugPrint('DEBUG [LendingRepository]: getPaymentHistory called with invalid ID: $loanId');
      return [];
    }
    try {
      debugPrint('DEBUG [LendingRepository]: Fetching payment history for loan: $loanId');
      final response = await _apiService.get('/loans/$loanId/payments');
      final List data = response['data'] ?? [];
      return data.map((e) => TransactionModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('DEBUG [LendingRepository]: Error fetching payment history for $loanId: $e');
      rethrow;
    }
  }

  Future<double> getTotalDisbursed() async {
    final response = await _apiService.get('/stats/total-disbursed');
    if (response != null && response['total'] != null) {
      return (response['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<double> getInterestRate() async {
    final response = await _apiService.get('/settings/interest-rate');
    if (response != null && response['rate'] != null) {
      return (response['rate'] as num).toDouble();
    }
    return 0.032; // Default fallback
  }

  Future<void> updateInterestRate({
    required double oldRate,
    required double newRate,
    required String reason,
    required DateTime effectiveDate,
  }) async {
    await _apiService.post('/settings/interest-rate', body: {
      'old_rate': oldRate,
      'new_rate': newRate,
      'reason': reason,
      'effective_date': effectiveDate.toIso8601String(),
    });
  }

  Future<List<dynamic>> getInterestRateHistory() async {
    final response = await _apiService.get('/settings/interest-rate/history');
    return response['data'] ?? [];
  }

  Future<List<LendingChartData>> getMetrics({String range = 'month'}) async {
    final response = await _apiService.get('/lending/metrics', queryParams: {'range': range});
    final List data = response['data'] ?? [];
    return data.map((e) => LendingChartData.fromJson(e)).toList();
  }
}
