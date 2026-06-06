import '../utils/parsers.dart';

class ShareholderModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String contactNumber;
  final String address;
  final double totalShareCapital;
  final int creditScore;
  final String? idImageUrl;

  ShareholderModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.totalShareCapital,
    required this.creditScore,
    this.idImageUrl,
  });

  factory ShareholderModel.fromJson(Map<String, dynamic> json) {
    return ShareholderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userid']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 'Unnamed',
      email: json['email']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      totalShareCapital: Parsers.parseDouble(json['total_share_capital']),
      creditScore: Parsers.parseInt(json['creditscore'] ?? json['credit_score']),
      idImageUrl: json['id_image_url']?.toString(),
    );
  }
}
