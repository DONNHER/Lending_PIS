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
  });

  String get fullName => '$firstName $lastName';
  String get role => 'Shareholder';
  double get totalShareCapital => shareCapital;

  factory ShareholderModel.fromJson(Map<String, dynamic> json) {
    return ShareholderModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      creditScore: (json['credit_score'] ?? 0.0).toDouble(),
      shareCapital: (json['share_capital'] ?? 0.0).toDouble(),
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'credit_score': creditScore,
      'share_capital': shareCapital,
      'avatar_url': avatarUrl,
    };
  }
}
