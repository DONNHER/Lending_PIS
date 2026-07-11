import 'package:flutter/material.dart';
import 'package:capstone_application/models/consignment_model.dart';
import 'package:capstone_application/models/consignment_daily_inventory.dart';
import 'package:capstone_application/repositories/consignment_products_repository.dart';
import 'package:capstone_application/repositories/daily_inventory_repository.dart';

enum ConsignmentDetailState { idle, loading, error, success }

class ConsignmentDetailViewModel extends ChangeNotifier {
  final ConsignmentProductsRepository _consignmentRepo;
  final DailyInventoryRepository _inventoryRepo;

  ConsignmentDetailState _state = ConsignmentDetailState.idle;
  ConsignmentWithDetails? _consignment;
  List<ConsignmentDailyInventoryModel> _inventories = [];
  bool _isLoading = false;
  String? _errorMessage;

  ConsignmentDetailViewModel(
    this._consignmentRepo,
    this._inventoryRepo,
  );

  ConsignmentDetailState get state => _state;
  ConsignmentWithDetails? get consignment => _consignment;
  List<ConsignmentDailyInventoryModel> get inventories => _inventories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stats
  int get totalReceived => _inventories.fold(0, (sum, item) => sum + item.received);
  int get totalSold => _inventories.fold(0, (sum, item) => sum + item.sold);
  int get totalReturned => _inventories.fold(0, (sum, item) => sum + item.returned);
  
  double get totalRevenue => _consignment != null 
    ? totalSold * _consignment!.product.sellingPrice 
    : 0.0;
    
  double get totalCommission => _consignment != null 
    ? totalRevenue * _consignment!.consignment.commissionRate 
    : 0.0;
    
  double get totalPayout => totalRevenue - totalCommission;

  void seedConsignment(ConsignmentWithDetails consignment) {
    _consignment = consignment;
    _state = ConsignmentDetailState.success;
    notifyListeners();
  }

  Future<void> loadDetails(String id) async {
    _isLoading = true;
    _state = ConsignmentDetailState.loading;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _inventories = []; // Start with empty for mock
      _state = ConsignmentDetailState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ConsignmentDetailState.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteInventory(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _inventories.removeWhere((item) => item.id == id);
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
