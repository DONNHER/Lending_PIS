// Represents a single consignee (supplier) in the system
class ConsigneeModel {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final String? healthCardUrl;      // nullable — images are optional
  final String? foodHandlerCardUrl; // nullable — images are optional
  final DateTime? createdAt;

  const ConsigneeModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    this.healthCardUrl,
    this.foodHandlerCardUrl,
    this.createdAt,
  });

  factory ConsigneeModel.fromJson(Map<String, dynamic> json) {
    return ConsigneeModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      healthCardUrl: json['health_card'] as String?,
      foodHandlerCardUrl: json['food_handler_card'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // IMPORTANT: only include non-null image URLs in the payload.
  // Sending an explicit null for a column that has no default will
  // cause Supabase to try to write NULL — which triggers a NOT NULL
  // violation (reported as an RLS error in Supabase's error surface).
  // By omitting the key entirely when the value is null, Postgres
  // simply uses whatever default the column has (NULL if nullable).
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'address': address,
      // Only add these keys when we actually have a URL to store.
      if (healthCardUrl != null) 'health_card': healthCardUrl,
      if (foodHandlerCardUrl != null) 'food_handler_card': foodHandlerCardUrl,
    };
  }

  ConsigneeModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? address,
    String? healthCardUrl,
    String? foodHandlerCardUrl,
    DateTime? createdAt,
  }) {
    return ConsigneeModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      healthCardUrl: healthCardUrl ?? this.healthCardUrl,
      foodHandlerCardUrl: foodHandlerCardUrl ?? this.foodHandlerCardUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}