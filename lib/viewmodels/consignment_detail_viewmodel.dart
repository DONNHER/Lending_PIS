import 'package:flutter/foundation.dart';
import '../models/consignment_daily_inventory.dart';
import '../repositories/consignment_products_repository.dart';
import '../repositories/daily_inventory_repository.dart';

enum DetailState { idle, loading, error }

class ConsignmentDetailViewModel extends ChangeNotifier {
  final ConsignmentProductsRepository _consignmentRepo;
  final DailyInventoryRepository _inventoryRepo;

  ConsignmentWithDetails? _consignment;
  List<ConsignmentDailyInventoryModel> _inventories = [];
  DetailState _state = DetailState.idle;
  String? _errorMessage;

  ConsignmentDetailViewModel(this._consignmentRepo, this._inventoryRepo);

  // ─── Getters ──────────────────────────────────────────────────────────

  ConsignmentWithDetails? get consignment => _consignment;
  List<ConsignmentDailyInventoryModel> get inventories => _inventories;
  DetailState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == DetailState.loading;

  int get totalReceived =>
      _inventories.fold(0, (sum, inv) => sum + inv.quantityReceived);
  int get totalSold =>
      _inventories.fold(0, (sum, inv) => sum + inv.quantitySold);
  int get totalReturned => totalReceived - totalSold;

  double get totalRevenue =>
      totalSold * (_consignment?.product.sellingPrice ?? 0);
  double get totalCommission =>
      totalRevenue * (_consignment?.consignment.commissionRate ?? 0);
  double get totalPayout => totalRevenue - totalCommission;

  // ─── Seed ─────────────────────────────────────────────────────────────

  void seedConsignment(ConsignmentWithDetails consignment) {
    _consignment = consignment;
  }

  // ─── Load ─────────────────────────────────────────────────────────────

  // ✅ FIX: DB has no consignment_id column — look up by product_id instead.
  //    Parameter kept as `consignmentId` so call-sites don't need to change,
  //    but internally we use _consignment.product.id for the actual query.
  Future<void> loadDetails(int consignmentId) async {
    if (_consignment == null) return;

    _state = DetailState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _inventories =
          await _inventoryRepo.getByProductId(_consignment!.product.id);
      debugPrint(
          'Loaded ${_inventories.length} inventory records for product ${_consignment!.product.id}');
      _state = DetailState.idle;
    } catch (e) {
      _state = DetailState.error;
      _errorMessage = e.toString();
      debugPrint('Error loading consignment details: $e');
    }

    notifyListeners();
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────

  Future<bool> addInventory({
    required DateTime consignmentDate,
    required int quantityReceived,
    required int quantitySold,
  }) async {
    if (_consignment == null) return false;

    try {
      await _inventoryRepo.add(
        // ✅ FIX: removed consignmentId param — column doesn't exist in DB
        productId: _consignment!.product.id,
        consignmentDate: consignmentDate,
        quantityReceived: quantityReceived,
        quantitySold: quantitySold,
      );
      await loadDetails(_consignment!.consignment.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding inventory: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInventory({
    required String inventoryId,
    required DateTime consignmentDate,
    required int quantityReceived,
    required int quantitySold,
  }) async {
    try {
      await _inventoryRepo.update(
        id: inventoryId,
        quantityReceived: quantityReceived,
        quantitySold: quantitySold,
        consignmentDate: consignmentDate,
      );
      await loadDetails(_consignment!.consignment.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating inventory: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInventory(String inventoryId) async {
    try {
      await _inventoryRepo.delete(inventoryId);
      await loadDetails(_consignment!.consignment.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting inventory: $e');
      notifyListeners();
      return false;
    }
  }
}