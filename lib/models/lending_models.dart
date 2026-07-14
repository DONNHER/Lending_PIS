enum ComakerStatus {
  pending,
  approved,
  rejected,
  released,
  cancelled,
}

enum LoanStatus {
  pending,
  approved,
  rejected,
  released,
  cancelled,
  fullyPaid,
  active,
  overdue,
}

class LendingChartData {
  final String period;
  final double totalDisbursed;
  final double shareCapital;

  LendingChartData({
    required this.period,
    required this.totalDisbursed,
    this.shareCapital = 0.0,
  });

  factory LendingChartData.fromJson(Map<String, dynamic> json) {
    return LendingChartData(
      period: json['period'] ?? '',
      totalDisbursed: _parseDouble(json['total_disbursed']),
      shareCapital: _parseDouble(json['share_capital']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class LoanComaker {
  final String shareholderId;
  final String shareholderName;
  final ComakerStatus status;

  LoanComaker({
    required this.shareholderId,
    required this.shareholderName,
    required this.status,
  });

  factory LoanComaker.fromJson(Map<String, dynamic> json) {
    return LoanComaker(
      shareholderId: json['shareholder_id']?.toString() ?? '',
      shareholderName: json['shareholder_name'] ?? 'Unknown',
      status: _parseStatus(json['status']?.toString()),
    );
  }

  static ComakerStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return ComakerStatus.approved;
      case 'rejected': return ComakerStatus.rejected;
      case 'released': return ComakerStatus.released;
      case 'cancelled': return ComakerStatus.cancelled;
      default: return ComakerStatus.pending;
    }
  }
}

class LoanRequestModel {
  final String id;
  final String shareholderId;
  final String shareholderName;
  final double requestedAmount;
  final int months;
  final String purpose;
  final LoanStatus status;
  final DateTime createdAt;
  final double interestRate;
  final List<LoanComaker> effectiveComakers;

  LoanRequestModel({
    required this.id,
    required this.shareholderId,
    required this.shareholderName,
    required this.requestedAmount,
    required this.months,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.interestRate = 0.0,
    this.effectiveComakers = const [],
  });

  int get tenureMonths => months;
  List<LoanComaker> get comakerDecisionsList => effectiveComakers;

  Map<String, ComakerStatus> get comakerDecisionsMap {
    return {for (var c in effectiveComakers) c.shareholderId: c.status};
  }

  LoanRequestModel copyWith({
    String? id,
    String? shareholderId,
    String? shareholderName,
    double? requestedAmount,
    int? months,
    String? purpose,
    LoanStatus? status,
    DateTime? createdAt,
    double? interestRate,
    List<LoanComaker>? effectiveComakers,
  }) {
    return LoanRequestModel(
      id: id ?? this.id,
      shareholderId: shareholderId ?? this.shareholderId,
      shareholderName: shareholderName ?? this.shareholderName,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      months: months ?? this.months,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      interestRate: interestRate ?? this.interestRate,
      effectiveComakers: effectiveComakers ?? this.effectiveComakers,
    );
  }

  factory LoanRequestModel.fromJson(Map<String, dynamic> json) {
    List<LoanComaker> comakers = [];
    if (json['comakers'] is List) {
      comakers = (json['comakers'] as List).map((e) => LoanComaker.fromJson(e)).toList();
    } else if (json['comaker_decisions'] is Map) {
      (json['comaker_decisions'] as Map).forEach((key, value) {
        comakers.add(LoanComaker(
          shareholderId: key.toString(),
          shareholderName: 'Shareholder $key', 
          status: _parseComakerStatus(value.toString()),
        ));
      });
    }

    String name = json['shareholder_name'] ?? '';
    if (name.isEmpty && json['shareholder'] != null) {
      final sh = json['shareholder'];
      final firstName = sh['first_name'] ?? sh['firstname'] ?? '';
      final lastName = sh['last_name'] ?? sh['lastname'] ?? '';
      name = '$firstName $lastName'.trim();
    }
    if (name.isEmpty) name = 'Unknown Shareholder';

    // Handle multiple possible keys for amount
    double amount = 0.0;
    final amountVal = json['requested_amount'] ?? json['amount'];
    if (amountVal != null) {
      if (amountVal is num) {
        amount = amountVal.toDouble();
      } else if (amountVal is String) {
        amount = double.tryParse(amountVal) ?? 0.0;
      }
    }

    return LoanRequestModel(
      id: json['id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? '',
      shareholderName: name,
      requestedAmount: amount,
      months: json['months'] ?? 0,
      purpose: json['purpose'] ?? '',
      status: _parseLoanStatus(json['status']?.toString()),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      interestRate: (json['interest_rate'] ?? 0.0).toDouble(),
      effectiveComakers: comakers,
    );
  }

  static ComakerStatus _parseComakerStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return ComakerStatus.approved;
      case 'rejected': return ComakerStatus.rejected;
      case 'released': return ComakerStatus.released;
      case 'cancelled': return ComakerStatus.cancelled;
      default: return ComakerStatus.pending;
    }
  }

  static LoanStatus _parseLoanStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return LoanStatus.pending;
      case 'approved': return LoanStatus.approved;
      case 'rejected': return LoanStatus.rejected;
      case 'released': return LoanStatus.released;
      case 'cancelled': return LoanStatus.cancelled;
      case 'active': return LoanStatus.active;
      case 'fully_paid': return LoanStatus.fullyPaid;
      case 'overdue': return LoanStatus.overdue;
      default: return LoanStatus.pending;
    }
  }
}

class LoanModel {
  final String id;
  final String loanRequestId;
  final String shareholderId;
  final double principal;
  final double balance;
  final double remainingBalance;
  final double interestRate;
  final String status;
  final DateTime? releaseDate;
  final DateTime? nextRepaymentDate;
  final int tenureMonths;
  final DateTime? disbursedAt;
  final double processingFee;
  final double totalRepayableField;
  final double totalAmountToPay;

  LoanModel({
    required this.id,
    required this.loanRequestId,
    required this.shareholderId,
    required this.principal,
    required this.balance,
    required this.remainingBalance,
    required this.interestRate,
    required this.status,
    this.releaseDate,
    this.nextRepaymentDate,
    this.tenureMonths = 0,
    this.disbursedAt,
    this.processingFee = 0.0,
    this.totalRepayableField = 0.0,
    this.totalAmountToPay = 0.0,
  });

  double get principalAmount => principal;
  
  double get monthlyAmortization {
    if (tenureMonths <= 0) return 0;
    return totalRepayable / tenureMonths;
  }

  double get totalRepayable {
    if (totalRepayableField > 0) return totalRepayableField;
    return principal * (1 + (interestRate * tenureMonths));
  }

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id']?.toString() ?? '',
      loanRequestId: json['loan_request_id']?.toString() ?? '',
      shareholderId: json['shareholder_id']?.toString() ?? '',
      principal: _parseDouble(json['principal_amount']),
      balance: _parseDouble(json['balance']),
      remainingBalance: _parseDouble(json['remaining_balance'] ?? json['balance']),
      interestRate: _parseDouble(json['interest_rate']),
      status: json['status']?.toString() ?? 'active',
      releaseDate: json['release_date'] != null 
          ? DateTime.parse(json['release_date'].toString()) 
          : null,
      nextRepaymentDate: json['next_repayment_date'] != null 
          ? DateTime.parse(json['next_repayment_date'].toString()) 
          : null,
      tenureMonths: json['months'] ?? json['tenure_months'] ?? 0,
      disbursedAt: json['disbursed_at'] != null 
          ? DateTime.parse(json['disbursed_at'].toString()) 
          : null,
      processingFee: _parseDouble(json['processing_fee']),
      totalRepayableField: _parseDouble(json['total_repayable']),
      totalAmountToPay: _parseDouble(json['total_amount_to_pay']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
