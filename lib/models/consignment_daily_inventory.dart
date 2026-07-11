class ConsignmentDailyInventoryModel {
  final String id;
  final String consignmentId;
  final DateTime date;
  final int received;
  final int sold;
  final int returned;

  ConsignmentDailyInventoryModel({
    required this.id,
    required this.consignmentId,
    required this.date,
    this.received = 0,
    this.sold = 0,
    this.returned = 0,
  });

  int get quantityReceived => received;
  int get quantitySold => sold;
  int get quantityReturned => returned;
  int get quantityRemaining => received - sold - returned;

  DateTime get consignmentDate => date;

  factory ConsignmentDailyInventoryModel.fromJson(Map<String, dynamic> json) {
    return ConsignmentDailyInventoryModel(
      id: json['id']?.toString() ?? '',
      consignmentId: json['consignment_id']?.toString() ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      received: json['received'] ?? 0,
      sold: json['sold'] ?? 0,
      returned: json['returned'] ?? 0,
    );
  }
}
