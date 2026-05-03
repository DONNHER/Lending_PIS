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
      id: json['id'] as int,
      shareholderCreditId: json['shareholder_credit_id'] as String,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
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