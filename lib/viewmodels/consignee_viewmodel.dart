import 'package:flutter/material.dart';
import '../models/consignee_model.dart';

class ConsigneeViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  final List<ConsigneeModel> _consignees = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ConsigneeModel> get consignees => _consignees;

  Future<void> loadConsignees() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addConsignee({
    required String fullName,
    required String phone,
    required String address,
    List<int>? healthCardBytes,
    List<int>? foodHandlerCardBytes,
    String? healthCardFileName,
    String? foodHandlerCardFileName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateConsignee({
    required String id,
    required String fullName,
    required String phone,
    required String address,
    List<int>? healthCardBytes,
    List<int>? foodHandlerCardBytes,
    String? healthCardFileName,
    String? foodHandlerCardFileName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
