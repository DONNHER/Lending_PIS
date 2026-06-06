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

enum UserStatus {
  active,
  inactive,
  suspended;

  static UserStatus fromString(String? status) {
    if (status == null) return UserStatus.active;
    return UserStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => UserStatus.active,
    );
  }
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final UserStatus status;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.status = UserStatus.active,
    this.avatarUrl,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstname'] as String? ?? '',
      lastName: json['lastname'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'shareholder'),
      status: UserStatus.fromString(json['status'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstname': firstName,
      'lastname': lastName,
      'role': role.name,
      'status': status.name,
      'avatar_url': avatarUrl,
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    UserStatus? status,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}
