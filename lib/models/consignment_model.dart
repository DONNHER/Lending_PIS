import 'product_model.dart';
import 'consignee_model.dart';

class ConsignmentModel {
  final String id;
  final String consigneeId;
  final DateTime date;
  final String status;
  final double capitalPrice;
  final double commissionRate;

  ConsignmentModel({
    required this.id,
    required this.consigneeId,
    required this.date,
    required this.status,
    this.capitalPrice = 0.0,
    this.commissionRate = 0.0,
  });
}

class ConsignmentWithDetails {
  final ConsignmentModel consignment;
  final ProductModel product;
  final ConsigneeModel? consignee;

  ConsignmentWithDetails({
    required this.consignment,
    required this.product,
    this.consignee,
  });
}
