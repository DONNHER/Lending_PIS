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

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      referenceId: json['reference_id']?.toString(),
      shareholderId: json['shareholder_id']?.toString() ?? json['user_id']?.toString(),
      type: json['type'] ?? '',
      method: json['method'] ?? '',
      clientName: json['client_name'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      date: DateTime.parse(json['date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
