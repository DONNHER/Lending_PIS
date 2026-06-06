import '../utils/parsers.dart';

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
      id: Parsers.parseInt(json['id']),
      saleId: json['sale_id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? '',
      ratePercentage: Parsers.parseDouble(json['rate_percentage']),
      refundAmount: Parsers.parseDouble(json['refund_amount']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
