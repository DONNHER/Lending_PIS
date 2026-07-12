import 'package:flutter/material.dart';
import '../repositories/shareholder_repository.dart';
import '../models/shareholder_model.dart';

class ShareholderDetailViewModel extends ChangeNotifier {
  final ShareholderRepository _repository;
  
  bool _isLoading = false;
  ShareholderModel? _shareholder;
  List<dynamic> _auditTrail = [];
  List<dynamic> _loans = [];

  ShareholderDetailViewModel(this._repository);

  bool get isLoading => _isLoading;
  ShareholderModel? get shareholder => _shareholder;
  List<dynamic> get auditTrail => _auditTrail;
  List<dynamic> get loans => _loans;

  Future<void> loadShareholder(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _repository.getShareholderFullData(id);
      if (response != null && response['success'] == true) {
        final data = response['data'];
        _shareholder = ShareholderModel.fromJson(data);
        _auditTrail = response['audit_trail'] ?? [];
        _loans = data['loans'] ?? [];
      }
    } catch (e) {
      debugPrint('Error loading shareholder details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
