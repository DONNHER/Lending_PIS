import 'package:flutter/material.dart';
import '../models/lending_models/loan.dart';
import '../repositories/lending_repository.dart';

enum LendingState { idle, loading, error }

class LendingViewModel extends ChangeNotifier {
  final LendingRepository _repository;

  List<Loan> _loans = [];
  LendingState _state = LendingState.idle;
  String? _errorMessage;

  LendingViewModel(this._repository);

  // Getters
  List<Loan> get loans => _loans;
  LendingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LendingState.loading;

  /// Fetch loan requests from Supabase
  Future<void> loadLoanRequests() async {
    _state = LendingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _loans = await _repository.getAllLoanRequests();
      _state = LendingState.idle;
    } catch (e) {
      _state = LendingState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Update the status of a loan (Approve/Reject)
  Future<bool> updateLoanStatus(int loanId, String status) async {
    try {
      await _repository.updateLoanStatus(loanId, status);
      await loadLoanRequests(); // Refresh the list
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
