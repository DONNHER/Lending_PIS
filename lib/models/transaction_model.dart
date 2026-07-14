class TransactionModel {
  final String id;
  final String? referenceId;
  final String? shareholderId;
  final String type;
  final String method;
  final String clientName;
  final double amount;
  final String status;
  final DateTime date;

  TransactionModel({
    required this.id,
    this.referenceId,
    this.shareholderId,
    required this.type,
    required this.method,
    required this.clientName,
    required this.amount,
    required this.status,
    required this.date,
  });

  TransactionModel copyWith({
    String? id,
    String? referenceId,
    String? shareholderId,
    String? type,
    String? method,
    String? clientName,
    double? amount,
    String? status,
    DateTime? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      shareholderId: shareholderId ?? this.shareholderId,
      type: type ?? this.type,
      method: method ?? this.method,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      date: date ?? this.date,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String name = json['client_name'] ?? json['name'] ?? '';
    
    // Extract name from joined shareholder relationship if available
    if (name.isEmpty && json['shareholder'] != null) {
      final sh = json['shareholder'];
      final firstName = sh['first_name'] ?? sh['firstname'] ?? '';
      final lastName = sh['last_name'] ?? sh['lastname'] ?? '';
      name = '$firstName $lastName'.trim();
    }
    
    // If nested in a loan object
    if (name.isEmpty && json['loan'] != null && json['loan']['shareholder'] != null) {
      final sh = json['loan']['shareholder'];
      final firstName = sh['first_name'] ?? sh['firstname'] ?? '';
      final lastName = sh['last_name'] ?? sh['lastname'] ?? '';
      name = '$firstName $lastName'.trim();
    }

    if (name.isEmpty) name = 'Unknown Client';

    // Robust amount parsing
    double parsedAmount = 0.0;
    if (json['amount'] != null) {
      if (json['amount'] is num) {
        parsedAmount = (json['amount'] as num).toDouble();
      } else if (json['amount'] is String) {
        parsedAmount = double.tryParse(json['amount']) ?? 0.0;
      }
    }

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      referenceId: json['reference_id']?.toString(),
      shareholderId: json['shareholder_id']?.toString() ?? json['user_id']?.toString(),
      type: json['type'] ?? 'Transaction',
      method: json['method'] ?? json['payment_method'] ?? 'N/A',
      clientName: name,
      amount: parsedAmount,
      status: json['status'] ?? 'Pending',
      date: DateTime.parse(json['date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
