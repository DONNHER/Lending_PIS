class ShareCapitalModel {
  final String id;
  final String fundId;
  final String shareholderId;
  final String source;
  final double amount;
  final DateTime createdAt;

  ShareCapitalModel({
    required this.id,
    required this.fundId,
    required this.shareholderId,
    required this.source,
    required this.amount,
    required this.createdAt,
  });

  factory ShareCapitalModel.fromJson(Map<String, dynamic> json) {
    // Robust parsing for Supabase Decimal/BigInt strings
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ShareCapitalModel(
      id: json['id']?.toString() ?? '',
      fundId: json['fund_id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Unknown',
      amount: parseDouble(json['amount']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'fund_id': fundId,
        'shareholder_id': shareholderId,
        'source': source,
        'amount': amount,
        'created_at': createdAt.toIso8601String(),
      };
}
