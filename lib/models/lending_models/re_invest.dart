import 'package:intl/intl.dart';

class ReinvestmentModel {
  final int id;
  final int shareholderId;
  final double amount;
  final DateTime date;
  final String? source;      // e.g., 'dividend', 'interest_share', 'manual'
  final String? remarks;
  final String? referenceId; // Link to the specific dividend payout if applicable

  const ReinvestmentModel({
    required this.id,
    required this.shareholderId,
    required this.amount,
    required this.date,
    this.source,
    this.remarks,
    this.referenceId,
  });

  /// Factory to map Supabase JSON to the model
  factory ReinvestmentModel.fromJson(Map<String, dynamic> json) {
    return ReinvestmentModel(
      id: json['id'] as int,
      shareholderId: json['shareholder_id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      source: json['source'] as String?,
      remarks: json['remarks'] as String?,
      referenceId: json['reference_id'] as String?,
    );
  }

  /// Converts model back to JSON for database insertion
  /// Note: We omit 'id' and 'created_at' to let Supabase handle auto-generation
  Map<String, dynamic> toJson() {
    return {
      'shareholder_id': shareholderId,
      'amount': amount,
      if (source != null) 'source': source,
      if (remarks != null) 'remarks': remarks,
      if (referenceId != null) 'reference_id': referenceId,
    };
  }

  /// State management helper for ViewModels
  ReinvestmentModel copyWith({
    int? id,
    int? shareholderId,
    double? amount,
    DateTime? date,
    String? source,
    String? remarks,
    String? referenceId,
  }) {
    return ReinvestmentModel(
      id: id ?? this.id,
      shareholderId: shareholderId ?? this.shareholderId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      source: source ?? this.source,
      remarks: remarks ?? this.remarks,
      referenceId: referenceId ?? this.referenceId,
    );
  }

  // ─── UI Helpers ─────────────────────────────────────────────────────────

  /// Formatted amount (e.g., ₱2,500.00)
  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Clean date display (e.g., 09 May 2026)
  String get formattedDate => DateFormat('dd MMM yyyy').format(date);
}