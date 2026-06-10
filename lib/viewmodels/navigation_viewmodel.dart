import 'package:flutter/material.dart';
import '../models/nav_item_model.dart';
import '../models/user_model.dart';

class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  UserRole? _currentUserRole;

  int get selectedIndex => _selectedIndex;
  UserRole? get currentUserRole => _currentUserRole;

  static const int bottomNavCount = 5;

  void setUserRole(UserRole? role) {
    _currentUserRole = role;
    _selectedIndex = 0;
    notifyListeners();
  }

  void navigateTo(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  List<NavItemModel> _allNavItems() {
    return [
      const NavItemModel(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        route: '/dashboard',
        allowedRoles: [UserRole.admin, UserRole.cashier],
      ),
      const NavItemModel(
        label: 'Loans',
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment_rounded,
        route: '/loans',
        allowedRoles: [UserRole.admin],
      ),

      const NavItemModel(
        label: 'Users',
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        route: '/users',
        allowedRoles: [UserRole.admin],
      ),
      const NavItemModel(
        label: 'Transactions',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        route: '/transactions',
        allowedRoles: [UserRole.admin],
      ),
      const NavItemModel(
        label: 'Interest Rate',
        icon: Icons.percent_outlined,
        activeIcon: Icons.percent_rounded,
        route: '/update-interest',
        allowedRoles: [UserRole.admin],
      ),
      const NavItemModel(
        label: 'Activity logs',
        icon: Icons.history_outlined,
        activeIcon: Icons.history_rounded,
        route: '/activity-logs',
        allowedRoles: [UserRole.admin],
      ),
    ];
  }

  List<NavItemModel> getFilteredNavItems() {
    if (_currentUserRole == null) return [];
    return _allNavItems()
        .where((item) => item.isAllowedForRole(_currentUserRole!))
        .toList();
  }

  List<NavItemModel> getBottomNavItems() {
    final filtered = getFilteredNavItems();
    return filtered.length > bottomNavCount
        ? filtered.sublist(0, bottomNavCount)
        : filtered;
  }

  List<NavItemModel> getDrawerItems() {
    final filtered = getFilteredNavItems();
    return filtered.length > bottomNavCount
        ? filtered.sublist(bottomNavCount)
        : [];
  }

  int getBottomNavIndex() {
    final bottomItems = getBottomNavItems();
    if (bottomItems.isEmpty) return 0;
    return _selectedIndex < bottomItems.length ? _selectedIndex : 0;
  }
}
