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
    // Handle both 'shareholder' and 'shareholders' keys
    final shareholderData = json['shareholder'] ?? json['shareholders'];
    
    return ComakerModel(
      id: json['id']?.toString() ?? '',
      loanId: json['loan_id']?.toString() ?? json['loan_request_id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? json['shareholderId']?.toString() ?? '',
      shareholderName: shareholderData?['full_name']?.toString() ?? 
                       json['shareholder_name']?.toString() ?? 
                       json['full_name']?.toString() ?? 
                       'Unknown',
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

  String? get comakerApprovalBlockReason {
    if (loanComakers.isEmpty) return null;
    var anyRejected = false;
    var anyNotApproved = false;
    for (final sid in loanComakers) {
      final s = comakerDecisions[sid] ?? ComakerStatus.pending;
      if (s == ComakerStatus.rejected) {
        anyRejected = true;
      } else if (s != ComakerStatus.approved) {
        anyNotApproved = true;
      }
    }
    if (anyRejected) {
      return 'Cannot approve: at least one co-maker has rejected this loan request.';
    }
    if (anyNotApproved) {
      return 'Cannot approve: at least one co-maker has not approved yet. Wait until all co-makers approve.';
    }
    return null;
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
    );
  }

  factory LoanRequestModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse Comakers
    var comakersList = <ComakerModel>[];
    final rawLoanComakers = json['loan_comakers'] ?? json['comakers'];
    if (rawLoanComakers is List && rawLoanComakers.isNotEmpty) {
      if (rawLoanComakers[0] is Map) {
        comakersList = rawLoanComakers.map((c) => ComakerModel.fromJson(c as Map<String, dynamic>)).toList();
      }
    }

    // 2. Parse Comaker IDs
    var comakerIds = <String>[];
    if (rawLoanComakers is List && rawLoanComakers.isNotEmpty && rawLoanComakers[0] is! Map) {
      comakerIds = rawLoanComakers.map((id) => id.toString()).toList();
    }
    
    final coMakerIdsAlt = json['co_maker_ids'] ?? json['loan_comakers_ids'];
    if (coMakerIdsAlt is List) {
       final altIds = coMakerIdsAlt.map((id) => id.toString()).toList();
       for (var id in altIds) {
         if (!comakerIds.contains(id)) comakerIds.add(id);
       }
    }

    if (comakerIds.isEmpty && comakersList.isNotEmpty) {
      comakerIds = comakersList.map((c) => c.shareholderId).where((id) => id.isNotEmpty).toList();
    }

    // 3. Parse Comaker Decisions
    final decisions = <String, ComakerStatus>{};
    final rawDecisions = json['comaker_decisions'];
    if (rawDecisions is Map) {
      rawDecisions.forEach((k, v) {
        decisions[k.toString()] = ComakerStatus.fromString(v?.toString());
      });
    }

    // 4. Handle Shareholder data relationship
    final shareholderData = json['shareholder'] ?? json['shareholders'];

    return LoanRequestModel(
      id: json['id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? json['shareholderId']?.toString() ?? '',
      shareholderName: json['shareholder_name']?.toString() ?? 
                       json['full_name']?.toString() ?? 
                       shareholderData?['full_name']?.toString() ?? 
                       'Unknown Client',
      requestedAmount: parseDouble(json['requested_amount']),
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
    );
  }

  Map<String, dynamic> toJson() => {
        'shareholder_id': shareholderId,
        'requested_amount': requestedAmount,
        'interest_rate': interestRate,
        'months': tenureMonths,
        'purpose': purpose,
        'status': status.name,
        'loan_comakers': loanComakers,
        if (comakerDecisions.isNotEmpty)
          'comaker_decisions': {
            for (final e in comakerDecisions.entries) e.key: e.value.name,
          },
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
    // Handle both 'shareholder' and 'shareholders' keys
    final shareholderData = json['shareholder'] ?? json['shareholders'];

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      referenceId: json['reference_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Loan',
      method: json['method']?.toString() ?? 'Cash',
      shareholderId: json['shareholder_id']?.toString() ?? json['shareholderId']?.toString(),
      clientName: json['client_name']?.toString() ?? 
                  json['shareholder_name']?.toString() ??
                  shareholderData?['full_name']?.toString() ?? 
                  'Unknown',
      amount: parseDouble(json['amount']),
      status: json['status']?.toString() ?? 'Successful',
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString()) 
          : (json['release_date'] != null ? DateTime.parse(json['release_date'].toString()) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
        'reference_id': referenceId,
        'type': type,
        'method': method,
        'shareholder_id': shareholderId,
        'amount': amount,
        'status': status,
        'date': date.toIso8601String(),
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

class LoanModel {
  final String id;
  final String loanRequestId;
  final String shareholderId;
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
    'processing_fee': processingFee.toInt(), 
    'remaining_balance': remainingBalance,
    'monthly_amortization': monthlyAmortization.toInt(), 
    'total_amount_to_pay': totalRepayable,
    'total_repayable': totalRepayable,
    'release_date': disbursedAt.toIso8601String(),
    if (dispatchedAt != null) 'dispatched_at': dispatchedAt!.toIso8601String(),
    if (nextRepaymentDate != null) 'next_repayment_date': nextRepaymentDate!.toIso8601String(),
    'status': status,
  };

  LoanModel copyWith({
    String? id,
    String? loanRequestId,
    String? shareholderId,
    double? principalAmount,
    double? interestRate,
    int? tenureMonths,
    double? processingFee,
    double? remainingBalance,
    double? monthlyAmortization,
    double? totalRepayable,
    DateTime? disbursedAt,
    DateTime? dispatchedAt,
    DateTime? nextRepaymentDate,
    String? status,
  }) {
    return LoanModel(
      id: id ?? this.id,
      loanRequestId: loanRequestId ?? this.loanRequestId,
      shareholderId: shareholderId ?? this.shareholderId,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      processingFee: processingFee ?? this.processingFee,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      monthlyAmortization: monthlyAmortization ?? this.monthlyAmortization,
      totalRepayable: totalRepayable ?? this.totalRepayable,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      nextRepaymentDate: nextRepaymentDate ?? this.nextRepaymentDate,
      status: status ?? this.status,
    );
  }

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
