// Records patronage refunds given to shareholders
class PatronageRefundModel {
  final int id; // bigint auto-increment
  final String saleId;
  final String shareholderId;
  final double ratePercentage; // e.g., 5.0 = 5%
  final double refundAmount;
  final DateTime createdAt;

  const PatronageRefundModel({
    required this.id,
    required this.saleId,
    required this.shareholderId,
    required this.ratePercentage,
    required this.refundAmount,
    required this.createdAt,
  });

  factory PatronageRefundModel.fromJson(Map<String, dynamic> json) {
    return PatronageRefundModel(
      id: json['id'] as int,
      saleId: json['sale_id'] as String,
      shareholderId: json['shareholder_id'] as String,
      ratePercentage: (json['rate_percentage'] as num).toDouble(),
      refundAmount: (json['refund_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sale_id': saleId,
      'shareholder_id': shareholderId,
      'rate_percentage': ratePercentage,
      'refund_amount': refundAmount,
    };
  }

  PatronageRefundModel copyWith({
    int? id,
    String? saleId,
    String? shareholderId,
    double? ratePercentage,
    double? refundAmount,
    DateTime? createdAt,
  }) {
    return PatronageRefundModel(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      shareholderId: shareholderId ?? this.shareholderId,
      ratePercentage: ratePercentage ?? this.ratePercentage,
      refundAmount: refundAmount ?? this.refundAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}