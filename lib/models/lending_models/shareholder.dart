import 'package:intl/intl.dart';

class ShareholderModel {
  final int? id;
  final String customerId;
  final String fullName;
  final String email;      // Added field
  final String contact;    // Added field
  final double totalInvestment;
  final double ownershipPercentage;
  final DateTime? joinedAt;
  final String? status;

  const ShareholderModel({
    this.id,
    required this.customerId,
    required this.fullName,
    required this.email,      // Added to constructor
    required this.contact,    // Added to constructor
    required this.totalInvestment,
    this.ownershipPercentage = 0.0,
    this.joinedAt,
    this.status,
  });

  factory ShareholderModel.fromMap(Map<String, dynamic> map) {
    // Supabase usually returns joined data in a nested map called 'customers'
    final customerData = map['customers'] as Map<String, dynamic>?;

    return ShareholderModel(
      id: map['id'] is String ? int.tryParse(map['id']) : map['id'] as int?,
      customerId: map['customer_id'] as String? ?? '',
      
      // Pulling from nested customer data
      fullName: customerData?['full_name'] as String? ?? 'Unknown Shareholder',
      email: customerData?['email'] as String? ?? 'No Email',
      contact: customerData?['contact_number'] as String? ?? 'No Contact',
      
      totalInvestment: (map['total_investment'] as num?)?.toDouble() ?? 0.0,
      ownershipPercentage: (map['ownership_percentage'] as num?)?.toDouble() ?? 0.0,
      joinedAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      status: map['status'] as String? ?? 'active',
    );

    
  }

  // --- Fix for the 'memberSince' error ---
  // The UI is looking for 'memberSince', so we add a getter that formats joinedAt
  String get memberSince {
    if (joinedAt == null) return 'N/A';
    return DateFormat('MMMM dd, yyyy').format(joinedAt!);
  }

  // UI Helpers
  String get formattedInvestment => NumberFormat.currency(symbol: '₱').format(totalInvestment);
  String get formattedShare => '${ownershipPercentage.toStringAsFixed(1)}%';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'total_investment': totalInvestment,
      'status': status,
    };
  }
 
}