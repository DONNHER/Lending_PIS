import 'shareholder.dart';
import 'co_maker.dart';
import 'payment.dart';
import 'package:intl/intl.dart';

class Loan {
  final int? id;
  final int borrowerId;
  final int? coMakerId;
  final double amount;
  final double interestRate;
  final DateTime startDate;
  final DateTime dueDate;
  final String status; // 'pending', 'approved', 'rejected', 'paid'
  final String? approvedBy;
  final DateTime? createdAt;

  // --- Relationships ---
  final ShareholderModel? borrower;
  final CoMaker? coMaker;
  final List<Payment>? payments;

  const Loan({
    this.id,
    required this.borrowerId,
    this.coMakerId,
    required this.amount,
    required this.interestRate,
    required this.startDate,
    required this.dueDate,
    required this.status,
    this.approvedBy,
    this.createdAt,
    this.borrower,
    this.coMaker,
    this.payments,
  });

  // --- Calculations ---

  /// Total Interest = Principal * (Rate / 100)
  double get totalInterest => amount * (interestRate / 100);

  /// Total contract amount (Principal + Interest)
  double get totalContractAmount => amount + totalInterest;

  /// Calculates current debt after subtracting payments
  double get outstandingBalance {
    if (payments == null || payments!.isEmpty) return totalContractAmount;
    final totalPaid = payments!.fold(0.0, (sum, p) => sum + p.amount);
    return totalContractAmount - totalPaid;
  }

  // --- Mapping ---

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      borrowerId: map['borrower_id'] as int,
      coMakerId: map['co_maker_id'] as int?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interest_rate'] as num?)?.toDouble() ?? 0.0,
      startDate: map['start_date'] != null 
          ? DateTime.parse(map['start_date']) 
          : DateTime.now(),
      dueDate: map['due_date'] != null 
          ? DateTime.parse(map['due_date']) 
          : DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      approvedBy: map['approved_by']?.toString(),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,

      // Hydrating Borrower (Table: customers)
      borrower: map['customers'] != null 
          ? ShareholderModel.fromMap(map['ShareholderModel']) 
          : null,
      
      // Hydrating Co-Maker
      coMaker: map['co_makers'] != null 
          ? CoMaker.fromMap(map['co_makers']) 
          : null,

      // Hydrating Payments
      payments: map['payments'] != null
          ? (map['payments'] as List).map((p) => Payment.fromMap(p)).toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'borrower_id': borrowerId,
      if (coMakerId != null) 'co_maker_id': coMakerId,
      'amount': amount,
      'interest_rate': interestRate,
      'start_date': startDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': status,
      if (approvedBy != null) 'approved_by': approvedBy,
    };
  }

  // --- UI Helpers ---

  String get formattedAmount => NumberFormat.currency(symbol: '₱').format(amount);
  
  String get formattedBalance => 
      NumberFormat.currency(symbol: '₱').format(outstandingBalance);
}