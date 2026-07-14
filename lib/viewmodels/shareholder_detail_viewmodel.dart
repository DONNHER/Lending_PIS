import 'package:flutter/material.dart';
import '../repositories/shareholder_repository.dart';
import '../models/shareholder_model.dart';
import '../models/activity_log_model.dart';

class ShareholderDetailViewModel extends ChangeNotifier {
  final ShareholderRepository _repository;
  
  bool _isLoading = false;
  ShareholderModel? _shareholder;
  List<ActivityLog> _auditTrail = [];
  List<dynamic> _loans = [];

  ShareholderDetailViewModel(this._repository);

  bool get isLoading => _isLoading;
  ShareholderModel? get shareholder => _shareholder;
  List<ActivityLog> get auditTrail => _auditTrail;
  List<dynamic> get loans => _loans;

  Map<String, dynamic>? get activeLoan {
    if (_loans.isEmpty) return null;
    try {
      return _loans.firstWhere(
        (l) {
          final status = l['status']?.toString().toLowerCase();
          return status == 'active' || status == 'released';
        },
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> loadShareholder(String id) async {
    final bool isDifferentUser = _shareholder?.id != id;
    if (isDifferentUser || _shareholder == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await _repository.getShareholderFullData(id);
      if (response != null && response['success'] == true) {
        final data = response['data'];
        _shareholder = ShareholderModel.fromJson(data);
        final List<dynamic> trailData = response['audit_trail'] ?? [];
        _auditTrail = trailData.map((json) => ActivityLog.fromJson(json)).toList();
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
