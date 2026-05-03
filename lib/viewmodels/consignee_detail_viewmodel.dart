import 'package:flutter/foundation.dart';
import '../models/consignee_model.dart';
import '../models/product_model.dart';
// import '../models/consignment_model.dart';
import '../repositories/consignee_repository.dart';
import '../repositories/consignment_repository.dart';

/// Represents a consigned product with its consignment details
class ConsignedProduct {
  final int consignmentId;
  final ProductModel product;
  final double commissionRate;
  final double capitalPrice;

  const ConsignedProduct({
    required this.consignmentId,
    required this.product,
    required this.commissionRate,
    required this.capitalPrice,
  });

  /// Factory to create from joined query result
  factory ConsignedProduct.fromJson(Map<String, dynamic> json) {
    return ConsignedProduct(
      consignmentId: json['id'] as int,
      product: ProductModel.fromJson(json['products'] as Map<String, dynamic>),
      commissionRate: (json['commission_rate'] as num).toDouble(),
      capitalPrice: (json['capital_price'] as num).toDouble(),
    );
  }
}

enum DetailViewState { idle, loading, error }

/// Manages state for the consignee detail page
class ConsigneeDetailViewModel extends ChangeNotifier {
  final ConsigneeRepository _consigneeRepository;
  final ConsignmentRepository _consignmentRepository;

  ConsigneeModel? _consignee;
  List<ConsignedProduct> _consignedProducts = [];
  DetailViewState _state = DetailViewState.idle;
  String? _errorMessage;

  ConsigneeDetailViewModel({
    required ConsigneeRepository consigneeRepository,
    required ConsignmentRepository consignmentRepository,
  })  : _consigneeRepository = consigneeRepository,
        _consignmentRepository = consignmentRepository;

  // Getters
  ConsigneeModel? get consignee => _consignee;
  List<ConsignedProduct> get consignedProducts => _consignedProducts;
  DetailViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == DetailViewState.loading;

  /// Load consignee details and their consigned products
  Future<void> loadDetails(String consigneeId) async {
    _state = DetailViewState.loading;
    notifyListeners();

    try {
      // Fetch consignee details
      _consignee = await _consigneeRepository.getById(consigneeId);

      // Fetch consigned products with product details
      final rawConsignments = await _consignmentRepository
          .getConsignmentsWithProducts(consigneeId);
      
      _consignedProducts = rawConsignments
          .map((json) => ConsignedProduct.fromJson(json))
          .toList();

      _state = DetailViewState.idle;
    } catch (e) {
      _state = DetailViewState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Add a new consigned product
  Future<bool> addConsignment({
    required String productId,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    if (_consignee == null) return false;

    try {
      // Check if product is already consigned to this consignee
      final alreadyExists = await _consignmentRepository
          .isProductAlreadyConsigned(
            productId: productId,
            consigneeId: _consignee!.id,
          );

      if (alreadyExists) {
        _errorMessage = 'This product is already consigned to this consignee';
        notifyListeners();
        return false;
      }

      await _consignmentRepository.add(
        productId: productId,
        consigneeId: _consignee!.id,
        commissionRate: commissionRate,
        capitalPrice: capitalPrice,
      );

      // Reload to refresh the list
      await loadDetails(_consignee!.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update an existing consignment
  Future<bool> updateConsignment({
    required int consignmentId,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    if (_consignee == null) return false;

    try {
      await _consignmentRepository.update(
        id: consignmentId,
        commissionRate: commissionRate,
        capitalPrice: capitalPrice,
      );

      await loadDetails(_consignee!.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a consignment
  Future<bool> deleteConsignment(int consignmentId) async {
    if (_consignee == null) return false;

    try {
      await _consignmentRepository.delete(consignmentId);
      await loadDetails(_consignee!.id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error state
  void clearError() {
    _errorMessage = null;
    _state = DetailViewState.idle;
    notifyListeners();
  }
}