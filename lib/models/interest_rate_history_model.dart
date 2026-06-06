class InterestRateHistoryModel {
  final String id;
  final double oldRate;
  final double newRate;
  final String reason;
  final DateTime effectiveDate;
  final DateTime createdAt;

  InterestRateHistoryModel({
    required this.id,
    required this.oldRate,
    required this.newRate,
    required this.reason,
    required this.effectiveDate,
    required this.createdAt,
  });

  factory InterestRateHistoryModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return InterestRateHistoryModel(
      id: json['id']?.toString() ?? '',
      oldRate: parseDouble(json['old_rate']),
      newRate: parseDouble(json['new_rate']),
      reason: json['reason']?.toString() ?? '',
      effectiveDate: json['effective_date'] != null 
          ? DateTime.parse(json['effective_date'].toString()) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'old_rate': oldRate,
        'new_rate': newRate,
        'reason': reason,
        'effective_date': effectiveDate.toIso8601String(),
      };
}
