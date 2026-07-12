
import 'shareholder_model.dart';

enum UserRole {
  admin,
  cashier,
  shareholder,
}

enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
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
  final String? idImageUrl;
  final String? address;
  final ShareholderModel? shareholder;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.idImageUrl,
    this.address,
    this.shareholder,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      role: _parseRole(json['role']),
      status: _parseStatus(json['status']),
      avatarUrl: json['avatar_url'],
      idImageUrl: json['id_image_url'],
      address: json['address'],
      shareholder: json['shareholder'] != null 
          ? ShareholderModel.fromJson(json['shareholder']) 
          : null,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'cashier':
      case 'staff':
        return UserRole.cashier;
      case 'shareholder':
      case 'member':
        return UserRole.shareholder;
      default:
        return UserRole.shareholder;
    }
  }

  static UserStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'suspended':
        return UserStatus.suspended;
      case 'pending':
        return UserStatus.pending;
      default:
        return UserStatus.active;
    }
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
      'id_image_url': idImageUrl,
      'address': address,
    };
  }
}
