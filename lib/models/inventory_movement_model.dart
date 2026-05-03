// Tracks all inventory changes (sales, restocks, adjustments, etc.)
class InventoryMovementModel {
  final String id;
  final String productId;
  final String? saleId; // Nullable — linked to a sale if movement is from a sale
  final String? groceryBatchId; // Nullable — linked if from a grocery batch
  final String movementType; // e.g., "sale", "restock", "adjustment", "expired"
  final int quantity; // smallint: negative for outgoing, positive for incoming
  final DateTime createdAt;
  final String? consignmentDailyInventory; // Nullable — linked to daily inventory

  const InventoryMovementModel({
    required this.id,
    required this.productId,
    this.saleId,
    this.groceryBatchId,
    required this.movementType,
    required this.quantity,
    required this.createdAt,
    this.consignmentDailyInventory,
  });

  // Check if this is an outgoing movement (sale, loss)
  bool get isOutgoing => quantity < 0;

  // Check if this is an incoming movement (restock)
  bool get isIncoming => quantity > 0;

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return InventoryMovementModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      saleId: json['sale_id'] as String?,
      groceryBatchId: json['grocery_batch_id'] as String?,
      movementType: json['movement_type'] as String,
      quantity: json['quantity'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      consignmentDailyInventory: json['consignment_daily_inventory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'sale_id': saleId,
      'grocery_batch_id': groceryBatchId,
      'movement_type': movementType,
      'quantity': quantity,
      'consignment_daily_inventory': consignmentDailyInventory,
    };
  }

  InventoryMovementModel copyWith({
    String? id,
    String? productId,
    String? saleId,
    String? groceryBatchId,
    String? movementType,
    int? quantity,
    DateTime? createdAt,
    String? consignmentDailyInventory,
  }) {
    return InventoryMovementModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      saleId: saleId ?? this.saleId,
      groceryBatchId: groceryBatchId ?? this.groceryBatchId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      consignmentDailyInventory: consignmentDailyInventory ?? this.consignmentDailyInventory,
    );
  }
}