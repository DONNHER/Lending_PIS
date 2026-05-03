// Enum matching your payment_type in database
enum PaymentType {
  cash,
  credit;

  static PaymentType fromString(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => PaymentType.cash,
    );
  }
}

// Represents a sale transaction
class SaleModel {
  final String id;
  final String cashierId;
  final String? shareholderId; // Nullable — only for shareholder credit sales
  final PaymentType paymentType;
  final DateTime createdAt;

  const SaleModel({
    required this.id,
    required this.cashierId,
    this.shareholderId,
    required this.paymentType,
    required this.createdAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String,
      cashierId: json['cashier_id'] as String,
      shareholderId: json['shareholder_id'] as String?,
      paymentType: PaymentType.fromString(json['payment_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashier_id': cashierId,
      'shareholder_id': shareholderId,
      'payment_type': paymentType.name,
    };
  }

  SaleModel copyWith({
    String? id,
    String? cashierId,
    String? shareholderId,
    PaymentType? paymentType,
    DateTime? createdAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      cashierId: cashierId ?? this.cashierId,
      shareholderId: shareholderId ?? this.shareholderId,
      paymentType: paymentType ?? this.paymentType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}