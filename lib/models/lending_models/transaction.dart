import 'package:intl/intl.dart';

enum TransactionType {
  disbursement, // Outflow: Money lent to borrower
  repayment,    // Inflow: Money paid back by borrower
  contribution, // Inflow: Shareholder adds capital
  withdrawal,   // Outflow: Shareholder takes capital
  adjustment,   // Neutral/Variable: Fees, taxes, or manual corrections
}

class TransactionEntry {
  final int id;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String partyName;    // Name of Borrower or Shareholder
  final String referenceId;  // e.g., 'LOAN-101', 'PAY-505'
  final String? description;

  const TransactionEntry({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.partyName,
    required this.referenceId,
    this.description,
  });

  /// Factory for standard JSON mapping (if coming from a unified view/table)
  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      id: json['id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null 
          ? DateTime.parse(json['date'] as String) 
          : DateTime.now(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == (json['type'] as String),
        orElse: () => TransactionType.adjustment,
      ),
      partyName: json['party_name'] as String? ?? 'Unknown',
      referenceId: json['reference_id'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  /// Converts the entry back to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'party_name': partyName,
      'reference_id': referenceId,
      if (description != null) 'description': description,
    };
  }

  /// Creates a copy of the entry with updated fields
  TransactionEntry copyWith({
    int? id,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? partyName,
    String? referenceId,
    String? description,
  }) {
    return TransactionEntry(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      partyName: partyName ?? this.partyName,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
    );
  }

  // ─── UI Helpers ─────────────────────────────────────────────────────────

  /// Returns true if the transaction adds money to the fund
  bool get isIncome => 
      type == TransactionType.repayment || 
      type == TransactionType.contribution;

  /// Returns a formatted string (e.g., ₱1,250.00)
  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return formatter.format(amount.abs());
  }

  /// Returns a clean date string (e.g., May 08, 2026)
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
}