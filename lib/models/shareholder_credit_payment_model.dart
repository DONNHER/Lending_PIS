import '../utils/parsers.dart';

// Records individual payments made toward shareholder credits
class ShareholderCreditPaymentModel {
  final int id; // bigint auto-increment
  final String shareholderCreditId;
  final double amountPaid;
  final DateTime createdAt;

  const ShareholderCreditPaymentModel({
    required this.id,
    required this.shareholderCreditId,
    required this.amountPaid,
    required this.createdAt,
  });

  factory ShareholderCreditPaymentModel.fromJson(Map<String, dynamic> json) {
    return ShareholderCreditPaymentModel(
      id: Parsers.parseInt(json['id']),
      shareholderCreditId: json['shareholder_credit_id']?.toString() ?? '',
      amountPaid: Parsers.parseDouble(json['amount_paid']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareholder_credit_id': shareholderCreditId,
      'amount_paid': amountPaid,
    };
  }

  ShareholderCreditPaymentModel copyWith({
    int? id,
    String? shareholderCreditId,
    double? amountPaid,
    DateTime? createdAt,
  }) {
    return ShareholderCreditPaymentModel(
      id: id ?? this.id,
      shareholderCreditId: shareholderCreditId ?? this.shareholderCreditId,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
