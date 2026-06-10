import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum LoanStatus {
  pending,
  approved,
  released,
  rejected,
  cancelled,
  fullyPaid;

  static LoanStatus fromString(String? status) {
    if (status == null) return LoanStatus.pending;
    return LoanStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => LoanStatus.pending,
    );
  }
}

enum ChartFilter { week, month, year }

enum ComakerStatus {
  pending,
  approved,
  rejected;

  static ComakerStatus fromString(String? status) {
    if (status == null) return ComakerStatus.pending;
    return ComakerStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => ComakerStatus.pending,
    );
  }
}

double parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

int parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// 🚀 Robust helper to extract full name from any nested JSON structure (Loan, Request, or Transaction)
String _extractClientName(Map<String, dynamic> json) {
  // 1. Try direct keys first (often provided by API accessors or direct fields)
  final List<String> directKeys = ['shareholder_name', 'full_name', 'client_name', 'name'];
  for (var key in directKeys) {
    final val = json[key]?.toString().trim();
    if (val != null && val.isNotEmpty && val.toLowerCase() != 'null' && val.toLowerCase() != 'unknown') {
      return val;
    }
  }

  // 2. Try nested shareholder data
  final sh = json['shareholder'] ?? json['shareholders'];
  if (sh is Map) {
    // Try full_name in shareholder
    final shFullName = sh['full_name']?.toString().trim();
    if (shFullName != null && shFullName.isNotEmpty && shFullName.toLowerCase() != 'null') {
      return shFullName;
    }
    
    // Try concatenating first and last name from shareholder
    final fn = (sh['first_name'] ?? sh['firstname'] ?? '').toString().trim();
    final ln = (sh['last_name'] ?? sh['lastname'] ?? '').toString().trim();
    if (fn.isNotEmpty || ln.isNotEmpty) {
      return "$fn $ln".trim();
    }
    
    // 3. Try nested User data inside Shareholder
    final u = sh['user'];
    if (u is Map) {
      final ufn = (u['firstname'] ?? u['first_name'] ?? '').toString().trim();
      final uln = (u['lastname'] ?? u['last_name'] ?? '').toString().trim();
      if (ufn.isNotEmpty || uln.isNotEmpty) {
        return "$ufn $uln".trim();
      }
    }
  }

  // 4. Try root-level nested user
  final rootUser = json['user'];
  if (rootUser is Map) {
    final ufn = (rootUser['firstname'] ?? rootUser['first_name'] ?? '').toString().trim();
    final uln = (rootUser['lastname'] ?? rootUser['last_name'] ?? '').toString().trim();
    if (ufn.isNotEmpty || uln.isNotEmpty) {
      return "$ufn $uln".trim();
    }
  }

  // 5. Fallback to Shareholder ID as a recognizable label
  final id = (json['shareholder_id'] ?? json['shareholderId'] ?? json['id'] ?? '').toString();
  if (id.isNotEmpty && id != 'null' && id.length > 5) {
    return "Member ${id.substring(0, 8)}";
  }
  
  return 'Unknown Client';
}

class ComakerModel {
  final String id;
  final String loanId;
  final String shareholderId;
  final String shareholderName;
  final ComakerStatus status;

  ComakerModel({
    required this.id,
    required this.loanId,
    required this.shareholderId,
    required this.shareholderName,
    required this.status,
  });

  factory ComakerModel.fromJson(Map<String, dynamic> json) {
    return ComakerModel(
      id: json['id']?.toString() ?? '',
      loanId: json['loan_id']?.toString() ?? json['loan_request_id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? json['shareholderId']?.toString() ?? '',
      shareholderName: _extractClientName(json),
      status: ComakerStatus.fromString(json['status']?.toString()),
    );
  }
}

class InterestRateModel {
  final String id;
  final double rate;
  final String description;
  final bool isActive;

  InterestRateModel({
    required this.id,
    required this.rate,
    required this.description,
    this.isActive = true,
  });

  factory InterestRateModel.fromJson(Map<String, dynamic> json) {
    return InterestRateModel(
      id: json['id']?.toString() ?? '',
      rate: parseDouble(json['rate']),
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class LoanRequestModel {
  final String id;
  final String shareholderId;
  final String shareholderName;
  final double requestedAmount;
  final double interestRate;
  final int tenureMonths;
  final String purpose;
  final LoanStatus status;
  final DateTime createdAt;
  final List<String> loanComakers;
  final List<ComakerModel> comakers;
  final Map<String, ComakerStatus> comakerDecisions;
  final String? comakerApprovalBlockReason;

  LoanRequestModel({
    required this.id,
    required this.shareholderId,
    required this.shareholderName,
    required this.requestedAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.loanComakers = const [],
    this.comakers = const [],
    this.comakerDecisions = const {},
    this.comakerApprovalBlockReason,
  });

  List<ComakerModel> get effectiveComakers {
    if (comakers.isNotEmpty) return comakers;
    if (loanComakers.isEmpty) return [];
    return loanComakers
        .map(
          (sid) => ComakerModel(
            id: '',
            loanId: id,
            shareholderId: sid,
            shareholderName: 'Co-maker',
            status: comakerDecisions[sid] ?? ComakerStatus.pending,
          ),
        )
        .toList();
  }

  LoanRequestModel copyWith({
    String? id,
    String? shareholderId,
    String? shareholderName,
    double? requestedAmount,
    double? interestRate,
    int? tenureMonths,
    String? purpose,
    LoanStatus? status,
    DateTime? createdAt,
    List<String>? loanComakers,
    List<ComakerModel>? comakers,
    Map<String, ComakerStatus>? comakerDecisions,
    String? comakerApprovalBlockReason,
  }) {
    return LoanRequestModel(
      id: id ?? this.id,
      shareholderId: shareholderId ?? this.shareholderId,
      shareholderName: shareholderName ?? this.shareholderName,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      loanComakers: loanComakers ?? this.loanComakers,
      comakers: comakers ?? this.comakers,
      comakerDecisions: comakerDecisions ?? this.comakerDecisions,
      comakerApprovalBlockReason: comakerApprovalBlockReason ?? this.comakerApprovalBlockReason,
    );
  }

  factory LoanRequestModel.fromJson(Map<String, dynamic> json) {
    var comakersList = <ComakerModel>[];
    final rawLoanComakers = json['loan_comakers'] ?? json['comakers'];
    if (rawLoanComakers is List && rawLoanComakers.isNotEmpty) {
      if (rawLoanComakers[0] is Map) {
        comakersList = rawLoanComakers.map((c) => ComakerModel.fromJson(c as Map<String, dynamic>)).toList();
      }
    }

    var comakerIds = <String>[];
    if (rawLoanComakers is List && rawLoanComakers.isNotEmpty && rawLoanComakers[0] is! Map) {
      comakerIds = rawLoanComakers.map((id) => id.toString()).toList();
    }

    final decisions = <String, ComakerStatus>{};
    final rawDecisions = json['comaker_decisions'];
    if (rawDecisions is Map) {
      rawDecisions.forEach((k, v) {
        decisions[k.toString()] = ComakerStatus.fromString(v?.toString());
      });
    }

    return LoanRequestModel(
      id: json['id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? json['shareholderId']?.toString() ?? '',
      shareholderName: _extractClientName(json),
      requestedAmount: parseDouble(json['requested_amount'] ?? json['amount']),
      interestRate: parseDouble(json['interest_rate'] ?? 0.032),
      tenureMonths: parseInt(json['months'] ?? json['tenure_months'] ?? 1),
      purpose: json['purpose']?.toString() ?? '',
      status: LoanStatus.fromString(json['status']?.toString()),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      loanComakers: comakerIds,
      comakers: comakersList,
      comakerDecisions: decisions,
      comakerApprovalBlockReason: json['comaker_approval_block_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shareholder_id': shareholderId,
        'requested_amount': requestedAmount,
        'interest_rate': interestRate,
        'months': tenureMonths,
        'purpose': purpose,
        'status': status.name,
        'loan_comakers': loanComakers,
      };
}

class TransactionModel {
  final String id;
  final String referenceId;
  final String type;
  final String method;
  final String? shareholderId;
  final String clientName;
  final double amount;
  final String status;
  final DateTime date;

  TransactionModel({
    required this.id,
    required this.referenceId,
    required this.type,
    required this.method,
    this.shareholderId,
    required this.clientName,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? json['idx']?.toString() ?? '',
      referenceId: json['reference_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Loan',
      method: json['method']?.toString() ?? 'Cash',
      shareholderId: json['shareholder_id']?.toString() ?? json['shareholderId']?.toString(),
      clientName: _extractClientName(json),
      amount: parseDouble(json['amount']),
      status: json['status']?.toString() ?? 'Successful',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString()) 
          : (json['release_date'] != null ? DateTime.parse(json['release_date'].toString()) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference_id': referenceId,
        'type': type,
        'method': method,
        'shareholder_id': shareholderId,
        'amount': amount,
        'status': status,
        'date': date.toIso8601String(),
      };
}

class LoanModel {
  final String id;
  final String loanRequestId;
  final String shareholderId;
  final String shareholderName;
  final double principalAmount;
  final double interestRate;
  final int tenureMonths;
  final double processingFee;
  final double remainingBalance;
  final double monthlyAmortization;
  final double totalRepayable;
  final DateTime disbursedAt;
  final DateTime? dispatchedAt;
  final DateTime? nextRepaymentDate;
  final String status;

  const LoanModel({
    required this.id,
    required this.loanRequestId,
    required this.shareholderId,
    required this.shareholderName,
    required this.principalAmount,
    required this.interestRate,
    required this.tenureMonths,
    required this.processingFee,
    required this.remainingBalance,
    required this.monthlyAmortization,
    required this.totalRepayable,
    required this.disbursedAt,
    this.dispatchedAt,
    this.nextRepaymentDate,
    this.status = 'active',
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id']?.toString() ?? '',
      loanRequestId: json['loan_request_id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? json['shareholderId']?.toString() ?? '',
      shareholderName: _extractClientName(json),
      principalAmount: parseDouble(json['principal_amount']),
      interestRate: parseDouble(json['interest_rate']),
      tenureMonths: parseInt(json['tenure_months']),
      processingFee: parseDouble(json['processing_fee']),
      remainingBalance: parseDouble(json['remaining_balance']),
      monthlyAmortization: parseDouble(json['monthly_amortization']),
      totalRepayable: parseDouble(json['total_repayable'] ?? json['total_amount_to_pay']),
      disbursedAt: DateTime.parse(
        json['release_date'] ?? json['disbursed_at'] ?? DateTime.now().toIso8601String(),
      ),
      dispatchedAt: json['dispatched_at'] != null
          ? DateTime.parse(json['dispatched_at'])
          : null,
      nextRepaymentDate: json['next_repayment_date'] != null
          ? DateTime.parse(json['next_repayment_date'])
          : null,
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'loan_request_id': loanRequestId,
    'shareholder_id': shareholderId,
    'principal_amount': principalAmount,
    'interest_rate': interestRate,
    'tenure_months': tenureMonths,
    'release_date': disbursedAt.toIso8601String(),
    'status': status,
  };
}

class LendingChartData {
  final String period;
  final double shareCapital;
  final double totalDisbursed;

  LendingChartData({
    required this.period,
    required this.shareCapital,
    required this.totalDisbursed,
  });
}

class UserTrendData {
  final String label;
  final int count;

  UserTrendData({required this.label, required this.count});
}

class KpiCardData {
  final String label;
  final String value;
  final IconData icon;

  KpiCardData({
    required this.label,
    required this.value,
    required this.icon,
  });
}
