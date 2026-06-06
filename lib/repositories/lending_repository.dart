import 'package:flutter/foundation.dart';
import '../models/lending_models.dart';
import '../models/interest_rate_history_model.dart';
import '../services/api_service.dart';
import '../utils/parsers.dart';

class LendingRepository {
  final ApiService _api;

  LendingRepository(this._api);

  double _parseDouble(dynamic value) {
    return Parsers.parseDouble(value);
  }

  Future<Map<String, dynamic>?> getDashboardStats({String range = 'week'}) async {
    try {
      final response = await _api.get('/dashboard/stats', queryParams: {'range': range});
      if (response != null && response['success'] == true) {
        return response;
      }
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
    }
    return null;
  }

  Future<List<LendingChartData>> getLendingChartMetrics(ChartFilter filter) async {
    try {
      final response = await _api.get('/lending/metrics', queryParams: {'filter': filter.name});
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((e) => LendingChartData(
          period: e['period']?.toString() ?? '',
          shareCapital: _parseDouble(e['share_capital']),
          totalDisbursed: _parseDouble(e['total_disbursed']),
        )).toList();
      }
    } catch (e) {
      debugPrint('LendingRepo Metrics Error: $e');
    }
    return [];
  }

  Future<LoanModel?> getLoanById(String id) async {
    try {
      final response = await _api.get('/loans/$id');
      if (response != null && response['success'] == true) {
        return LoanModel.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error fetching loan: $e');
    }
    return null;
  }

  Future<List<LoanModel>> getLoansByShareholderId(String shareholderId) async {
    try {
      final response = await _api.get('/shareholders/$shareholderId/loans');
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => LoanModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching shareholder loans: $e');
    }
    return [];
  }

  Future<String> createLoanRequest(LoanRequestModel request, List<String> comakerIds) async {
    final response = await _api.post('/loan-requests', body: {
      ...request.toJson(),
      'comaker_ids': comakerIds,
    });
    if (response != null && response['success'] == true) {
      return response['data']['id'].toString();
    }
    throw Exception('Failed to create loan request');
  }

  Future<LoanRequestModel?> getLoanRequestById(dynamic id) async {
    try {
      final response = await _api.get('/loan-requests/$id');
      if (response != null && response['success'] == true) {
        return LoanRequestModel.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error fetching loan request: $id $e');
    }
    return null;
  }

  Future<List<LoanRequestModel>> getLoanRequests({
    String? status,
    int? offset,
    int? limit,
    String? shareholderId,
    String? orderColumn,
    bool? ascending,
  }) async {
    try {
      final Map<String, String> params = {};
      if (status != null) params['status'] = status;
      if (offset != null) params['offset'] = offset.toString();
      if (limit != null) params['limit'] = limit.toString();
      if (shareholderId != null) params['shareholder_id'] = shareholderId;

      final response = await _api.get('/loan-requests', queryParams: params);
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => LoanRequestModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching loan requests: $e');
    }
    return [];
  }

  Future<int> getLoanRequestsCount({String? status, String? shareholderId}) async {
    try {
      final Map<String, String> params = {};
      if (status != null) params['status'] = status;
      if (shareholderId != null) params['shareholder_id'] = shareholderId;
      
      final response = await _api.get('/loan-requests/count', queryParams: params);
      if (response != null && response['success'] == true) {
        return Parsers.parseInt(response['count']);
      }
    } catch (e) {
      debugPrint('Error fetching requests count: $e');
    }
    return 0;
  }

  Future<void> setComakerDecision({
    required dynamic loanRequestId,
    required String comakerShareholderId,
    required ComakerStatus status,
    String remarks = '',
  }) async {
    await _api.post('/loan-requests/$loanRequestId/comaker-decision', body: {
      'shareholder_id': comakerShareholderId,
      'status': status.name,
      'remarks': remarks,
    });
  }

  Future<double> getTotalDisbursedLoans() async {
    try {
      final response = await _api.get('/stats/total-disbursed');
      if (response != null && response['success'] == true) {
        return _parseDouble(response['total']);
      }
    } catch (e) {
      debugPrint('Error getting total disbursed: $e');
    }
    return 0.0;
  }

  Future<double> getTotalShareholderCapital() async {
    try {
      final response = await _api.get('/stats/total-capital');
      if (response != null && response['success'] == true) {
        return _parseDouble(response['total']);
      }
    } catch (e) {
      debugPrint('Error getting total capital: $e');
    }
    return 0.0;
  }

  Future<List<TransactionModel>> getRecentLoanTransactions({int limit = 5}) async {
    final response = await _api.get('/transactions', queryParams: {'limit': limit.toString()});
    if (response != null && response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((e) => TransactionModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<LoanModel?> getLoanByLoanRequestId(dynamic requestId) async {
    try {
      final response = await _api.get('/loans/by-request/$requestId');
      if (response != null && response['success'] == true) {
        return LoanModel.fromJson(response['data']);
      }
    } catch (e) {
      debugPrint('Error fetching loan by request ID: $e');
    }
    return null;
  }

  Future<String?> checkLoanEligibility(String shareholderId) async {
    try {
      final response = await _api.get('/shareholders/$shareholderId/eligibility');
      if (response != null && response['success'] == true) {
        return response['eligible'] == true ? null : (response['message']?.toString() ?? 'Not eligible');
      }
    } catch (e) {
      debugPrint('Error checking eligibility: $e');
    }
    return 'Could not verify eligibility';
  }

  Future<void> updateLoanRequestStatus(dynamic id, dynamic status, {LoanRequestModel? request}) async {
    final statusString = status is String ? status : status.toString().split('.').last;
    await _api.put('/loan-requests/$id/status', body: {
      'status': statusString,
      if (request != null) ...request.toJson(),
    });
  }

  Future<void> disburseLoan(dynamic loanOrRequest) async {
    final id = (loanOrRequest is LoanModel) ? loanOrRequest.loanRequestId : (loanOrRequest is LoanRequestModel ? loanOrRequest.id : loanOrRequest);
    await _api.post('/loan-requests/$id/disburse');
  }

  Future<void> recordLoanPayment({
    required String loanId,
    required double amount,
    required String method,
    String? reference,
  }) async {
    await _api.post('/loans/$loanId/payments', body: {
      'amount': amount,
      'method': method,
      'reference': reference,
    });
  }

  Future<int> getActiveLoansCount() async {
    try {
      final response = await _api.get('/stats/active-loans-count');
      if (response != null && response['success'] == true) {
        return Parsers.parseInt(response['count']);
      }
    } catch (e) {
      debugPrint('Error getting active loans count: $e');
    }
    return 0;
  }

  Future<double> getCurrentInterestRate() async {
    try {
      final response = await _api.get('/settings/interest-rate');
      if (response != null && response['success'] == true) {
        return _parseDouble(response['rate']);
      }
    } catch (e) {
      debugPrint('Error fetching interest rate: $e');
    }
    return 0.032;
  }

  Future<List<InterestRateHistoryModel>> getInterestRateHistory() async {
    final response = await _api.get('/settings/interest-rate/history');
    if (response != null && response['success'] == true) {
      final List<dynamic> data = response['data'];
      return data.map((e) => InterestRateHistoryModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> updateInterestRate(InterestRateHistoryModel entry) async {
    await _api.post('/settings/interest-rate', body: entry.toJson());
  }

  Stream<List<LoanRequestModel>> getLoanRequestsStream() async* {
    while (true) {
      yield await getLoanRequests();
      await Future.delayed(const Duration(seconds: 10));
    }
  }
}
