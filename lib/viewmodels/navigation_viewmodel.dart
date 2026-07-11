import 'package:flutter/material.dart';
import 'package:capstone_application/models/user_model.dart';
import 'package:capstone_application/models/nav_item_model.dart';

class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  UserRole? _currentUserRole;

  int get selectedIndex => _selectedIndex;
  UserRole? get currentUserRole => _currentUserRole;

  final List<NavItemModel> _allItems = [
    const NavItemModel(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      route: '/dashboard',
      allowedRoles: [UserRole.admin, UserRole.cashier],
    ),
    const NavItemModel(
      label: 'Loans',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      route: '/loans',
      allowedRoles: [UserRole.admin, UserRole.cashier],
    ),
    const NavItemModel(
      label: 'Transactions',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      route: '/transactions',
      allowedRoles: [UserRole.admin, UserRole.cashier],
    ),
    const NavItemModel(
      label: 'Users',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      route: '/users',
      allowedRoles: [UserRole.admin],
    ),
    const NavItemModel(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      route: '/update-interest',
      allowedRoles: [UserRole.admin],
    ),
    const NavItemModel(
      label: 'Logs',
      icon: Icons.history_rounded,
      activeIcon: Icons.history_toggle_off_rounded,
      route: '/activity-logs',
      allowedRoles: [UserRole.admin],
    ),
  ];

  void setUserRole(UserRole role) {
    _currentUserRole = role;
    _selectedIndex = 0;
    notifyListeners();
  }

  void navigateTo(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  List<NavItemModel> getFilteredNavItems() {
    if (_currentUserRole == null) return [];
    return _allItems.where((item) => item.allowedRoles.contains(_currentUserRole)).toList();
  }

  List<NavItemModel> getBottomNavItems() {
    final filtered = getFilteredNavItems();
    if (filtered.length <= 4) return filtered;
    return filtered.take(4).toList();
  }

  List<NavItemModel> getDrawerItems() {
    final filtered = getFilteredNavItems();
    if (filtered.length <= 4) return [];
    return filtered.skip(4).toList();
  }

  int getBottomNavIndex() {
    if (_selectedIndex < 4) return _selectedIndex;
    return -1; // Not in bottom nav
  }
}
