import 'shareholder.dart';
import 'package:intl/intl.dart';

class LoanRequestModel {
  final int? id;
  final int borrowerId;
  final double requestedAmount;
  final double interestRate; 
  final String purpose;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedDate;
  final DateTime? dueDate; // Added dueDate
  final double? approvedAmount;
  final String? rejectionReason;
  
  // --- Relationships ---
  final ShareholderModel? borrower; // Joined from shareholders table

  const LoanRequestModel({
    this.id,
    required this.borrowerId,
    required this.requestedAmount,
    required this.interestRate, 
    required this.purpose,
    required this.status,
    required this.requestedDate,
    this.dueDate,
    this.approvedAmount,
    this.rejectionReason,
    this.borrower,
  });

  /// Factory to map Supabase data. 
  factory LoanRequestModel.fromMap(Map<String, dynamic> map) {
    return LoanRequestModel(
      id: map['id'] as int?,
      borrowerId: map['borrower_id'] as int,
      requestedAmount: (map['requested_amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0.0, 
      purpose: map['purpose'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      requestedDate: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : DateTime.now(),
      dueDate: map['due_date'] != null 
          ? DateTime.parse(map['due_date'] as String) 
          : null,
      approvedAmount: (map['approved_amount'] as num?)?.toDouble(),
      rejectionReason: map['rejection_reason'] as String?,
      
      // Hydrating Borrower data
      borrower: map['shareholders'] != null 
          ? ShareholderModel.fromMap(map['shareholders']) 
          : null,
    );
  }

  /// Converts the model back to JSON for database storage.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'borrower_id': borrowerId,
      'requested_amount': requestedAmount,
      'interest_rate': interestRate, 
      'purpose': purpose,
      'status': status,
      if (dueDate != null) 'due_date': dueDate?.toIso8601String(),
      if (approvedAmount != null) 'approved_amount': approvedAmount,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };
  }

  /// Facilitates state updates
  LoanRequestModel copyWith({
    int? id,
    int? borrowerId,
    double? requestedAmount,
    double? interestRate, 
    String? purpose,
    String? status,
    DateTime? requestedDate,
    DateTime? dueDate,
    double? approvedAmount,
    String? rejectionReason,
    ShareholderModel? borrower,
  }) {
    return LoanRequestModel(
      id: id ?? this.id,
      borrowerId: borrowerId ?? this.borrowerId,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      interestRate: interestRate ?? this.interestRate, 
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      requestedDate: requestedDate ?? this.requestedDate,
      dueDate: dueDate ?? this.dueDate,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      borrower: borrower ?? this.borrower,
    );
  }

  // ─── UI Helpers ─────────────────────────────────────────────────────────

  String get formattedRequestedAmount => 
      NumberFormat.currency(symbol: '₱').format(requestedAmount);

  String get formattedDate => 
      DateFormat('MMM dd, yyyy').format(requestedDate);

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
