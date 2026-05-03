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
        label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded, route: '/dashboard',
        allowedRoles: [UserRole.admin, UserRole.shareholder],
      ),
      const NavItemModel(
        label: 'Point of Sale', icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale_rounded, route: '/pos',
        allowedRoles: [UserRole.admin, UserRole.cashier],
      ),
      const NavItemModel(
        label: 'Consignments', icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded, route: '/consignment-products',
        allowedRoles: [UserRole.admin, UserRole.cashier],
      ),
      const NavItemModel(
        label: 'Groceries', icon: Icons.inventory_rounded,
        activeIcon: Icons.inventory_rounded, route: '/grocery-products',
        allowedRoles: [UserRole.admin, UserRole.cashier],
      ),
      const NavItemModel(
        label: 'Consignees', icon: Icons.local_shipping_outlined,
        activeIcon: Icons.local_shipping_rounded, route: '/consignees',
        allowedRoles: [UserRole.admin],
      ),
      const NavItemModel(
        label: 'Sales', icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded, route: '/sales',
        allowedRoles: [UserRole.admin, UserRole.cashier, UserRole.shareholder],
      ),
      const NavItemModel(
        label: 'Inventory', icon: Icons.swap_horiz_outlined,
        activeIcon: Icons.swap_horiz_rounded, route: '/inventory',
        allowedRoles: [UserRole.admin, UserRole.cashier],
      ),
      const NavItemModel(
        label: 'Shareholders', icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded, route: '/shareholders',
        allowedRoles: [UserRole.admin, UserRole.shareholder],
      ),
      const NavItemModel(
        label: 'Reports', icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded, route: '/reports',
        allowedRoles: [UserRole.admin, UserRole.shareholder],
      ),
      const NavItemModel(
        label: 'Cashiers', icon: Icons.badge_outlined,
        activeIcon: Icons.badge_rounded, route: '/cashiers',
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
    return _selectedIndex < getBottomNavItems().length ? _selectedIndex : 0;
  }
}