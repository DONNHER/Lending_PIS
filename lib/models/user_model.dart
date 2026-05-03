enum UserRole {
  admin,
  cashier,
  shareholder;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => UserRole.cashier,
    );
  }
}

class UserModel {
  final String id;       // public.users UUID
  final String authId;   // auth.users UUID
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String middleName;
  final UserRole role;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.authId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.role,
    this.createdAt,
  });

  String get fullName =>
      '$firstName ${middleName.isNotEmpty ? '${middleName[0]}. ' : ''}$lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      authId: json['auth_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstname'] as String,
      lastName: json['lastname'] as String,
      middleName: json['middlename'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // password is intentionally excluded — managed by Supabase Auth
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'firstname': firstName,
      'lastname': lastName,
      'middlename': middleName,
      'role': role.name,
    };
  }

  UserModel copyWith({
    String? id,
    String? authId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? middleName,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}