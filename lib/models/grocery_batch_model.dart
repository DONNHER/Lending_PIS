import '../utils/parsers.dart';

// Tracks individual batches of grocery items with expiration tracking
class GroceryBatchModel {
  final String id;
  final String productId;
  final double capitalPrice;
  final int originalQuantity;
  final int remainingQuantity;
  final DateTime purchaseDate;
  final DateTime expirationDate;
  final DateTime? createdAt;

  const GroceryBatchModel({
    required this.id,
    required this.productId,
    required this.capitalPrice,
    required this.originalQuantity,
    required this.remainingQuantity,
    required this.purchaseDate,
    required this.expirationDate,
    this.createdAt,
  });

  // Computed property: how many have been sold/used
  int get quantityUsed => originalQuantity - remainingQuantity;

  // Check if batch is expired
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  // Check if batch is about to expire (within 7 days)
  bool get isExpiringSoon => 
      !isExpired && DateTime.now().add(const Duration(days: 7)).isAfter(expirationDate);

  factory GroceryBatchModel.fromJson(Map<String, dynamic> json) {
    return GroceryBatchModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      capitalPrice: Parsers.parseDouble(json['capital_price']),
      originalQuantity: Parsers.parseInt(json['original_quantity']),
      remainingQuantity: Parsers.parseInt(json['remaining_quantity']),
      purchaseDate: json['purchase_date'] != null 
          ? DateTime.parse(json['purchase_date'] as String)
          : DateTime.now(),
      expirationDate: json['expiration_date'] != null 
          ? DateTime.parse(json['expiration_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'capital_price': capitalPrice,
      'original_quantity': originalQuantity,
      'remaining_quantity': remainingQuantity,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'expiration_date': expirationDate.toIso8601String().split('T')[0],
    };
  }

  GroceryBatchModel copyWith({
    String? id,
    String? productId,
    double? capitalPrice,
    int? originalQuantity,
    int? remainingQuantity,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    DateTime? createdAt,
  }) {
    return GroceryBatchModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      capitalPrice: capitalPrice ?? this.capitalPrice,
      originalQuantity: originalQuantity ?? this.originalQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
