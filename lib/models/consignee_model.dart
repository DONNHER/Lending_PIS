class ConsigneeModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String? healthCardUrl;
  final String? foodHandlerCardUrl;

  ConsigneeModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.healthCardUrl,
    this.foodHandlerCardUrl,
  });

  factory ConsigneeModel.fromJson(Map<String, dynamic> json) {
    return ConsigneeModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      healthCardUrl: json['health_card_url'],
      foodHandlerCardUrl: json['food_handler_card_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'health_card_url': healthCardUrl,
      'food_handler_card_url': foodHandlerCardUrl,
    };
  }
}
