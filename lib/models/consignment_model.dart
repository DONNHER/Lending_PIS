// Links a product to a consignee with pricing details
// This is the junction table between products and consignees
class ConsignmentModel {
  final int id; // bigint auto-increment
  final String productId;
  final String consigneeId;
  final double commissionRate; // e.g., 0.20 = 20% commission
  final double capitalPrice; // cost price from consignee

  const ConsignmentModel({
    required this.id,
    required this.productId,
    required this.consigneeId,
    required this.commissionRate,
    required this.capitalPrice,
  });

  factory ConsignmentModel.fromJson(Map<String, dynamic> json) {
    return ConsignmentModel(
      id: json['id'] as int,
      productId: json['product_id'] as String,
      consigneeId: json['consignee_id'] as String,
      commissionRate: (json['commission_rate'] as num).toDouble(),
      capitalPrice: (json['capital_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'consignee_id': consigneeId,
      'commission_rate': commissionRate,
      'capital_price': capitalPrice,
    };
  }

  ConsignmentModel copyWith({
    int? id,
    String? productId,
    String? consigneeId,
    double? commissionRate,
    double? capitalPrice,
  }) {
    return ConsignmentModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      consigneeId: consigneeId ?? this.consigneeId,
      commissionRate: commissionRate ?? this.commissionRate,
      capitalPrice: capitalPrice ?? this.capitalPrice,
    );
  }
}