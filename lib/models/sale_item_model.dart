import '../utils/parsers.dart';

// Individual items within a sale transaction
class SaleItemModel {
  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final double sellingPrice;

  // Computed property
  double get subtotal => quantity * sellingPrice;

  const SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.sellingPrice,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id']?.toString() ?? '',
      saleId: json['sale_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantity: Parsers.parseInt(json['quantity']),
      sellingPrice: Parsers.parseDouble(json['selling_price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'selling_price': sellingPrice,
    };
  }

  SaleItemModel copyWith({
    String? id,
    String? saleId,
    String? productId,
    int? quantity,
    double? sellingPrice,
  }) {
    return SaleItemModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      sellingPrice: sellingPrice ?? this.sellingPrice,
    );
  }
}
