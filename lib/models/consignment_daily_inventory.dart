// Tracks daily inventory for consignment products
class ConsignmentDailyInventoryModel {
  final String id;
  final String productId;
  final DateTime consignmentDate;
  final int quantityReceived; // smallint: -32,768 to 32,767
  final int quantitySold;

  const ConsignmentDailyInventoryModel({
    required this.id,
    required this.productId,
    required this.consignmentDate,
    required this.quantityReceived,
    required this.quantitySold,
  });

  // Computed property: how many are left
  int get quantityRemaining => quantityReceived - quantitySold;

  factory ConsignmentDailyInventoryModel.fromJson(Map<String, dynamic> json) {
    return ConsignmentDailyInventoryModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      consignmentDate: DateTime.parse(json['consignment_date'] as String),
      quantityReceived: json['quantity_received'] as int,
      quantitySold: json['quantity_sold'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'consingment_date': consignmentDate.toIso8601String().split('T')[0],
      'quantity_received': quantityReceived,
      'quantity_sold': quantitySold,
    };
  }

  ConsignmentDailyInventoryModel copyWith({
    String? id,
    String? productId,
    DateTime? consignmentDate,
    int? quantityReceived,
    int? quantitySold,
  }) {
    return ConsignmentDailyInventoryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      consignmentDate: consignmentDate ?? this.consignmentDate,
      quantityReceived: quantityReceived ?? this.quantityReceived,
      quantitySold: quantitySold ?? this.quantitySold,
    );
  }
}