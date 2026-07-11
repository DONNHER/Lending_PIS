import 'package:flutter/material.dart';
import '../repositories/shareholder_repository.dart';
import '../models/shareholder_model.dart';

class ShareholderDetailViewModel extends ChangeNotifier {
  final ShareholderRepository _repository;
  
  bool _isLoading = false;
  ShareholderModel? _shareholder;
  List<dynamic> _auditTrail = [];

  ShareholderDetailViewModel(this._repository);

  bool get isLoading => _isLoading;
  ShareholderModel? get shareholder => _shareholder;
  List<dynamic> get auditTrail => _auditTrail;

  Future<void> loadShareholder(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _repository.getShareholderFullData(id);
      if (response != null && response['success'] == true) {
        _shareholder = ShareholderModel.fromJson(response['data']);
        _auditTrail = response['audit_trail'] ?? [];
      }
    } catch (e) {
      debugPrint('Error loading shareholder details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
