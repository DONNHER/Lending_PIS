// Records payouts made to consignees for sold items
class ConsignmentPayoutModel {
  final String id;
  final String consignmentDailyInventoryId;
  final double payoutAmount;

  const ConsignmentPayoutModel({
    required this.id,
    required this.consignmentDailyInventoryId,
    required this.payoutAmount,
  });

  factory ConsignmentPayoutModel.fromJson(Map<String, dynamic> json) {
    return ConsignmentPayoutModel(
      id: json['id'] as String,
      consignmentDailyInventoryId: json['consignment_daily_inventory_id'] as String,
      payoutAmount: (json['payout_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consignment_daily_inventory_id': consignmentDailyInventoryId,
      'payout_amount': payoutAmount,
    };
  }

  ConsignmentPayoutModel copyWith({
    String? id,
    String? consignmentDailyInventoryId,
    double? payoutAmount,
  }) {
    return ConsignmentPayoutModel(
      id: id ?? this.id,
      consignmentDailyInventoryId: consignmentDailyInventoryId ?? this.consignmentDailyInventoryId,
      payoutAmount: payoutAmount ?? this.payoutAmount,
    );
  }
}