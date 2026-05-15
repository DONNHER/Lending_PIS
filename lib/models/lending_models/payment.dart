import 'package:intl/intl.dart';

class Payment {
  final int id;
  final int loanId;
  final double amount;
  final DateTime paymentDate;
  
  // Identifying the Payer
  final String payerId;      // The UserID (UUID) or Customer Serial
  final String? payerName;   // Joined from the customers table
  
  final String? paymentMethod; // e.g., 'cash', 'gcash', 'transfer'
  final String? notes;

  const Payment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paymentDate,
    required this.payerId,
    this.payerName,
    this.paymentMethod,
    this.notes,
  });

  /// Factory to map Supabase JSON/Map to the model.
  /// Renamed to 'fromMap' for consistency with Loan.fromMap
  factory Payment.fromMap(Map<String, dynamic> map) {
    // 1. Try to find customer data (for payer info) 
    // This handles both direct joins 'payments(customers(*))' 
    // and nested joins 'payments(loans(customers(*)))'
    final customerData = map['customers'] as Map<String, dynamic>? ?? 
                         map['loans']?['customers'] as Map<String, dynamic>?;

    return Payment(
      id: map['id'] as int? ?? 0,
      loanId: map['loan_id'] as int? ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'] as String)
          : (map['created_at'] != null 
              ? DateTime.parse(map['created_at'] as String) 
              : DateTime.now()),
      
      // Extraction of Payer Info: uses column payer_id OR joined customer id
      payerId: (map['payer_id']?.toString()) ?? 
               (customerData?['id']?.toString()) ?? '',
               
      payerName: customerData?['full_name'] as String? ?? 'Unknown Payer',
      
      paymentMethod: map['payment_method'] as String?,
      notes: map['notes'] as String?,
    );
  }

  /// Converts model to JSON for database storage.
  Map<String, dynamic> toMap() {
    return {
      'loan_id': loanId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payer_id': payerId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
    };
  }

  Payment copyWith({
    int? id,
    int? loanId,
    double? amount,
    DateTime? paymentDate,
    String? payerId,
    String? payerName,
    String? paymentMethod,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      payerId: payerId ?? this.payerId,
      payerName: payerName ?? this.payerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }

  // ─── UI Helpers ─────────────────────────────────────────────────────────

  String get formattedAmount => NumberFormat.currency(symbol: '₱').format(amount);

  String get formattedDate => DateFormat('dd MMM yyyy').format(paymentDate);

  String get displayMethod => paymentMethod != null && paymentMethod!.isNotEmpty
      ? paymentMethod![0].toUpperCase() + paymentMethod!.substring(1)
      : 'N/A';
}