import 'package:flutter/foundation.dart';
import '../utils/parsers.dart';

class ShareholderModel {
  final String id; // This is the shareholder_id (can be empty for non-shareholders)
  final String userId; // This is the user_id
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String contactNumber;
  final String address;
  final String status;
  final double totalShareCapital;
  final int creditScore;
  final String? idImageUrl;
  final double? membershipFee;
  final String role; 

  ShareholderModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.status,
    required this.totalShareCapital,
    required this.creditScore,
    this.idImageUrl,
    this.membershipFee,
    required this.role,
  });

  factory ShareholderModel.fromJson(Map<String, dynamic> json) {
    // 🚀 Robust Role Extraction
    String role = 'shareholder';
    if (json['role'] != null) {
      role = json['role'].toString();
    } else if (json['user'] is Map) {
      role = json['user']['role']?.toString() ?? 'shareholder';
    }
    
    // 🚀 Robust Status Extraction
    String status = 'Active';
    if (json['status'] != null) {
      status = json['status'].toString();
    } else if (json['user'] is Map && json['user']['status'] != null) {
      status = json['user']['status'].toString();
    }
    
    String shId = '';
    String uId = '';
    
    // Determine which ID is which based on the keys present
    // 1. Check if it's a primary Shareholder object (has user_id/userid)
    if (json.containsKey('user_id') || json.containsKey('userid')) {
      shId = json['id']?.toString() ?? '';
      uId = (json['user_id'] ?? json['userid'])?.toString() ?? '';
    } 
    // 2. Check if it's a User object with explicit shareholder_id
    else if (json.containsKey('shareholder_id') || json.containsKey('shareholderid')) {
      uId = json['id']?.toString() ?? '';
      shId = (json['shareholder_id'] ?? json['shareholderid'])?.toString() ?? '';
    }
    // 3. Fallback: Standard User object
    else {
      uId = json['id']?.toString() ?? '';
      if (json['shareholder'] is Map) {
        shId = json['shareholder']['id']?.toString() ?? '';
      }
      // If the record itself is nested under 'user' key
      if (uId == '' && json['user'] is Map) {
        return ShareholderModel.fromJson(json['user'] as Map<String, dynamic>);
      }
    }

    // 🚀 Defensive Nested Access for other fields
    dynamic shData = json['shareholder'] is Map ? json['shareholder'] : null;

    return ShareholderModel(
      id: shId,
      userId: uId,
      firstName: json['first_name']?.toString() ?? json['firstname']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? json['lastname']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? 
               (json['firstname'] != null ? "${json['firstname']} ${json['lastname']}" : 'Unnamed'),
      email: json['email']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? 
                    json['phone']?.toString() ?? 
                    json['contact_number']?.toString() ?? '',
      // 🚀 Prioritize address from shareholders table, fallback to users table
      address: (shData?['address'] as String?) ?? (json['address']?.toString() ?? ''),
      status: status,
      totalShareCapital: Parsers.parseDouble(json['total_share_capital'] ?? shData?['total_share_capital']),
      creditScore: Parsers.parseInt(json['creditscore'] ?? json['credit_score'] ?? shData?['credit_score']),
      idImageUrl: json['id_image_url']?.toString(),
      membershipFee: Parsers.parseDouble(json['membership_fee']),
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
      'contact_number': contactNumber,
      'address': address,
      'status': status,
      'total_share_capital': totalShareCapital,
      'creditscore': creditScore,
      'id_image_url': idImageUrl,
      'membership_fee': membershipFee,
      'role': role,
    };
  }
}
