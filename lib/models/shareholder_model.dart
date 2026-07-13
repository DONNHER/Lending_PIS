class ShareholderModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final double creditScore;
  final double shareCapital;
  final String? avatarUrl;
  final String? idImageUrl;

  ShareholderModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.creditScore = 0.0,
    this.shareCapital = 0.0,
    this.avatarUrl,
    this.idImageUrl,
  });

  String get fullName => '$firstName $lastName';
  String get role => 'Shareholder';
  double get totalShareCapital => shareCapital;

  factory ShareholderModel.fromJson(Map<String, dynamic> json) {
    return ShareholderModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] ?? json['firstname'] ?? '',
      lastName: json['last_name'] ?? json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['contact_number'] ?? json['phone'],
      address: json['address'],
      creditScore: (json['creditscore'] ?? json['credit_score'] ?? 0.0).toDouble(),
      shareCapital: _parseDouble(json['total_share_capital'] ?? json['share_capital']),
      avatarUrl: json['avatar_url'],
      idImageUrl: json['id_image_url'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'contact_number': phone,
      'address': address,
      'creditscore': creditScore,
      'total_share_capital': shareCapital,
      'avatar_url': avatarUrl,
      'id_image_url': idImageUrl,
    };
  }
}
