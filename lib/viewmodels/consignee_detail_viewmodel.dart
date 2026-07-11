import 'package:flutter/material.dart';
import '../models/consignee_model.dart';
import '../models/product_model.dart';

enum DetailViewState { idle, loading, error, success }

class ConsigneeDetailViewModel extends ChangeNotifier {
  DetailViewState _state = DetailViewState.idle;
  ConsigneeModel? _consignee;
  final List<ConsignedProduct> _consignedProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  DetailViewState get state => _state;
  ConsigneeModel? get consignee => _consignee;
  List<ConsignedProduct> get consignedProducts => _consignedProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDetails(String id) async {
    _isLoading = true;
    _state = DetailViewState.loading;
    notifyListeners();
    
    try {
      // Mock loading data
      await Future.delayed(const Duration(milliseconds: 500));
      _state = DetailViewState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = DetailViewState.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addConsignment({
    required String productId,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Logic to add
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

  Future<void> updateConsignment({
    required int consignmentId,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Logic to update
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteConsignment(int consignmentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Logic to delete
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class ConsignedProduct {
  final int consignmentId;
  final ProductModel product;
  final double commissionRate;
  final double capitalPrice;

  ConsignedProduct({
    required this.consignmentId,
    required this.product,
    required this.commissionRate,
    required this.capitalPrice,
  });
}
