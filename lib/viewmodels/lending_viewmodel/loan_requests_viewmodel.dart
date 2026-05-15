import 'package:flutter/material.dart';

import 'package:capstone_application/repositories/lending_repository/loan_requests_repository.dart';
import 'package:capstone_application/models/lending_models/loan_request.dart';

class LoanRequestViewModel extends ChangeNotifier {
  final LoanRequestRepository _repository;

  LoanRequestViewModel(this._repository);

  List<LoanRequestModel> _pendingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<LoanRequestModel> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> applyLoan(Map<String, dynamic> loanData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Call the repository to insert the loan record
      await _repository.submitLoanApplication(loanData);
      
      // 2. Optionally reload transactions/loans list to reflect changes
      // await loadTransactions(); 

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Fetches only pending requests for the management inbox
  Future<void> loadPendingRequests() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _pendingRequests = await _repository.getRequestsByStatus('pending');
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// The method the UI was looking for to handle approvals/rejections
  Future<void> updateRequestStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      await _repository.updateRequestStatus(
        requestId: requestId,
        status: status,
      );
      
      // Remove the updated request from the local list so the UI updates immediately
      _pendingRequests.removeWhere((req) => req.id == requestId);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to update: $e";
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}