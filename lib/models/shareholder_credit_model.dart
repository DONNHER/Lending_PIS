// Enum matching your status_type in database
enum CreditStatus {
  pending,
  paid,
  overdue;

  static CreditStatus fromString(String value) {
    return CreditStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => CreditStatus.pending,
    );
  }
}

// Tracks credit sales for shareholders
class ShareholderCreditModel {
  final String id;
  final String shareholderId;
  final String saleId;
  final CreditStatus status;
  final DateTime createdAt;

  const ShareholderCreditModel({
    required this.id,
    required this.shareholderId,
    required this.saleId,
    required this.status,
    required this.createdAt,
  });

  factory ShareholderCreditModel.fromJson(Map<String, dynamic> json) {
    return ShareholderCreditModel(
      id: json['id'] as String,
      shareholderId: json['shareholder_id'] as String,
      saleId: json['sale_id'] as String,
      status: CreditStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareholder_id': shareholderId,
      'sale_id': saleId,
      'status': status.name,
    };
  }

  ShareholderCreditModel copyWith({
    String? id,
    String? shareholderId,
    String? saleId,
    CreditStatus? status,
    DateTime? createdAt,
  }) {
    return ShareholderCreditModel(
      id: id ?? this.id,
      shareholderId: shareholderId ?? this.shareholderId,
      saleId: saleId ?? this.saleId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}