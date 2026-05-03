// Tracks which grocery batches were used for each sale item
class SaleItemBatchModel {
  final int id; // bigint auto-increment
  final String saleItemId;
  final String groceryBatchId;
  final int quantityTaken;

  const SaleItemBatchModel({
    required this.id,
    required this.saleItemId,
    required this.groceryBatchId,
    required this.quantityTaken,
  });

  factory SaleItemBatchModel.fromJson(Map<String, dynamic> json) {
    return SaleItemBatchModel(
      id: json['id'] as int,
      saleItemId: json['sale_item_id'] as String,
      groceryBatchId: json['grocery_batch_id'] as String,
      quantityTaken: json['quantity_taken'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sale_item_id': saleItemId,
      'grocery_batch_id': groceryBatchId,
      'quantity_taken': quantityTaken,
    };
  }

  SaleItemBatchModel copyWith({
    int? id,
    String? saleItemId,
    String? groceryBatchId,
    int? quantityTaken,
  }) {
    return SaleItemBatchModel(
      id: id ?? this.id,
      saleItemId: saleItemId ?? this.saleItemId,
      groceryBatchId: groceryBatchId ?? this.groceryBatchId,
      quantityTaken: quantityTaken ?? this.quantityTaken,
    );
  }
}