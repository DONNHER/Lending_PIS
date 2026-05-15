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
    if (_currentUserRole == role) return;
    _currentUserRole = role;
    _selectedIndex = 0; 
    notifyListeners();
  }

  void navigateTo(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void resetIndex() {
    _selectedIndex = 0;
    notifyListeners();
  }

  List<NavItemModel> allNavItems() {
    return [
      const NavItemModel(
        label: 'Dashboard', 
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded, 
        route: '/dashboard',
        allowedRoles: [UserRole.admin, UserRole.cashier, UserRole.shareholder],
      ),
      const NavItemModel(
        label: 'Loan Requests', 
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale_rounded, 
        route: '/loan-requests',
        allowedRoles: [UserRole.admin],
      ),
      const NavItemModel(
        label: 'Activity Logs', 
        icon: Icons.history_rounded,
        activeIcon: Icons.history_rounded, 
        route: '/activity-logs',
        allowedRoles: [UserRole.admin],
      ),
      const NavItemModel(
        label: 'Fund Management', 
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded, 
        route: '/fund-management',
        allowedRoles: [UserRole.admin],
      ),
      const NavItemModel(
        label: 'Shareholders', 
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded, 
        route: '/shareholders',
        allowedRoles: [UserRole.admin, UserRole.shareholder],
      ),
      const NavItemModel(
        label: 'Transactions', 
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded, 
        route: '/transactions', 
        allowedRoles: [UserRole.admin, UserRole.cashier, UserRole.shareholder],
      ),
    ];
  }

  List<NavItemModel> getFilteredNavItems() {
    if (_currentUserRole == null) return [];
    return allNavItems()
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
    final filtered = getFilteredNavItems();
    final bottomItemsCount = filtered.length > bottomNavCount ? bottomNavCount : filtered.length;
    if (bottomItemsCount == 0) return 0;
    return _selectedIndex < bottomItemsCount ? _selectedIndex : 0;
  }
}
