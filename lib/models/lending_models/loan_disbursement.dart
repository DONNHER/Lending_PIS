import 'package:intl/intl.dart';
import 'shareholder.dart'; // Using Shareholder instead of Customer

class LoanDisbursement {
  final int id;
  final int loanId;
  final double amount;
  final DateTime disbursementDate;
  final String method; // e.g., 'cash', 'gcash', 'bank_transfer'
  final String? referenceNumber; 
  final String? remarks;

  // --- Relationships ---
  // The person receiving the money is the shareholder/borrower
  final ShareholderModel? recipient; 

  const LoanDisbursement({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.disbursementDate,
    required this.method,
    this.referenceNumber,
    this.remarks,
    this.recipient,
  });

  /// Factory to map Supabase data using the 'fromMap' convention.
  factory LoanDisbursement.fromMap(Map<String, dynamic> map) {
    // Check for nested shareholder data through the loan link
    final loanData = map['loans'] as Map<String, dynamic>?;
    final shareholderData = map['shareholders'] as Map<String, dynamic>? ?? 
                            loanData?['shareholders'] as Map<String, dynamic>?;

    return LoanDisbursement(
      id: map['id'] as int? ?? 0,
      loanId: map['loan_id'] as int? ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      disbursementDate: map['disbursement_date'] != null
          ? DateTime.parse(map['disbursement_date'] as String)
          : (map['created_at'] != null 
              ? DateTime.parse(map['created_at'] as String) 
              : DateTime.now()),
      method: map['method'] as String? ?? 'cash',
      referenceNumber: map['reference_number'] as String?,
      remarks: map['remarks'] as String?,
      
      // Hydrate the shareholder/recipient info
      recipient: shareholderData != null ? ShareholderModel.fromMap(shareholderData) : null,
    );
  }

  /// Converts the model to a map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'loan_id': loanId,
      'amount': amount,
      'disbursement_date': disbursementDate.toIso8601String(),
      'method': method,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (remarks != null) 'remarks': remarks,
    };
  }

  /// Facilitates state updates in the ViewModel.
  LoanDisbursement copyWith({
    int? id,
    int? loanId,
    double? amount,
    DateTime? disbursementDate,
    String? method,
    String? referenceNumber,
    String? remarks,
    ShareholderModel? recipient,
  }) {
    return LoanDisbursement(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      method: method ?? this.method,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      remarks: remarks ?? this.remarks,
      recipient: recipient ?? this.recipient,
    );
  }

  // ─── UI Helpers ─────────────────────────────────────────────────────────

  String get formattedAmount => 
      NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(amount);

  String get formattedDate => 
      DateFormat('MMM dd, yyyy').format(disbursementDate);

  String get displayMethod => method.toUpperCase();
}