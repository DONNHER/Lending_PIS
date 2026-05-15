import 'package:flutter/foundation.dart';
import 'package:capstone_application/models/lending_models/shareholder.dart';
import 'package:capstone_application/repositories/lending_repository/shareholders_repository.dart';

enum ShareholderState { idle, loading, error }

class ShareholderViewModel extends ChangeNotifier {
  final ShareholderRepository _repository;

  List<ShareholderModel> _shareholders = [];
  ShareholderState _state = ShareholderState.idle;
  String? _errorMessage;

  ShareholderViewModel({required ShareholderRepository repository}) 
      : _repository = repository;

  // Getters
  List<ShareholderModel> get shareholders => _shareholders;
  ShareholderState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ShareholderState.loading;

  void setSearchQuery(String query) {
    filterShareholders(query); // Automatically trigger filter when query changes
  }

  /// NEW: Adds a shareholder by passing a data map to the repository
  Future<bool> addShareholder(Map<String, dynamic> data) async {
    _state = ShareholderState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Call repository to create the record (usually handles Supabase logic)
      await _repository.createShareholder(data);
      
      // 2. Refresh the local list so the UI reflects the new member
      await loadShareholders();
      
      _state = ShareholderState.idle;
      return true;
    } catch (e) {
      _state = ShareholderState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Loads all shareholders from the dedicated repository
  Future<void> loadShareholders() async {
    _state = ShareholderState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<ShareholderModel> data = await _repository.getAllShareholders();
      _shareholders = data;
      _state = ShareholderState.idle;
    } catch (e) {
      _state = ShareholderState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Add a new investment contribution
  Future<bool> recordContribution({
    required int shareholderId,
    required double amount,
    required DateTime date,
  }) async {
    try {
      await _repository.addContribution(shareholderId: shareholderId, amount: amount, date: date);
      await loadShareholders();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ShareholderState.error;
      notifyListeners();
      return false;
    }
  }

  /// Search/Filter shareholders locally
  void filterShareholders(String query) {
    if (query.isEmpty) {
      loadShareholders(); // Reset to full list
      return;
    }
    _shareholders = _shareholders
        .where((s) => s.fullName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _state = ShareholderState.idle;
    notifyListeners();
  }
}