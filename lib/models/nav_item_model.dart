import 'package:flutter/material.dart';
import 'package:capstone_application/models/user_model.dart';

class NavItemModel {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final List<UserRole> allowedRoles;

  const NavItemModel({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    required this.allowedRoles,
  });
}
