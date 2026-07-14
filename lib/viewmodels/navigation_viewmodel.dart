import 'package:flutter/material.dart';
import 'package:capstone_application/models/user_model.dart';
import 'package:capstone_application/models/nav_item_model.dart';
import 'package:capstone_application/models/shareholder_model.dart';
import 'package:capstone_application/models/lending_models.dart';

class NavigationViewModel extends ChangeNotifier {
  int _selectedIndex = 0;
  UserRole? _currentUserRole;
  String? _selectedShareholderId;
  LoanRequestModel? _selectedLoanRequest;
  String? _selectedLoanId;
  String? _selectedLoanShareholderId;
  
  // 🚀 Added for in-shell loan application and admin settings
  bool _isApplyingLoan = false;
  bool _isViewingAdminSettings = false;
  bool _isReviewingLoanRequest = false; // 🚀 Added
  String? _loanRequestIdToReview; // 🚀 Added
  ShareholderModel? _loanInitialShareholder;

  int get selectedIndex => _selectedIndex;
  UserRole? get currentUserRole => _currentUserRole;
  String? get selectedShareholderId => _selectedShareholderId;
  LoanRequestModel? get selectedLoanRequest => _selectedLoanRequest;
  String? get selectedLoanId => _selectedLoanId;
  String? get selectedLoanShareholderId => _selectedLoanShareholderId;
  
  bool get isApplyingLoan => _isApplyingLoan;
  bool get isViewingAdminSettings => _isViewingAdminSettings;
  bool get isReviewingLoanRequest => _isReviewingLoanRequest; // 🚀 Added
  String? get loanRequestIdToReview => _loanRequestIdToReview; // 🚀 Added
  ShareholderModel? get loanInitialShareholder => _loanInitialShareholder;

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
      label: 'Interest',
      icon: Icons.percent_rounded,
      activeIcon: Icons.percent_rounded,
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
    const NavItemModel(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: '/shareholder-dashboard',
      allowedRoles: [UserRole.shareholder],
    ),
    const NavItemModel(
      label: 'Transaction',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      route: '/shareholder-transactions',
      allowedRoles: [UserRole.shareholder],
    ),
    const NavItemModel(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: '/shareholder-profile',
      allowedRoles: [UserRole.shareholder],
    ),
  ];

  void setUserRole(UserRole role) {
    _currentUserRole = role;
    _selectedIndex = 0;
    _clearSubViews();
    notifyListeners();
  }

  void navigateTo(int index) {
    _selectedIndex = index;
    _clearSubViews();
    _isApplyingLoan = false; 
    _isViewingAdminSettings = false; // Reset settings view when switching tabs
    notifyListeners();
  }

  void navigateToLoanApplication(ShareholderModel? shareholder) {
    _isApplyingLoan = true;
    _isViewingAdminSettings = false;
    _loanInitialShareholder = shareholder;
    notifyListeners();
  }

  void navigateToAdminSettings() {
    _isViewingAdminSettings = true;
    _isApplyingLoan = false;
    notifyListeners();
  }

  void clearAdminSettings() {
    _isViewingAdminSettings = false;
    notifyListeners();
  }

  void clearLoanApplication() {
    _isApplyingLoan = false;
    _loanInitialShareholder = null;
    notifyListeners();
  }

  void navigateToLoanReview(String requestId) {
    _isReviewingLoanRequest = true;
    _loanRequestIdToReview = requestId;
    _isApplyingLoan = false;
    _isViewingAdminSettings = false;
    notifyListeners();
  }

  void clearLoanReview() {
    _isReviewingLoanRequest = false;
    _loanRequestIdToReview = null;
    notifyListeners();
  }

  void navigateToShareholder(String id) {
    final items = getFilteredNavItems();
    final index = items.indexWhere((item) => item.route == '/users');
    if (index != -1) {
      _selectedIndex = index;
      _clearSubViews();
      _selectedShareholderId = id;
      notifyListeners();
    }
  }

  void navigateToLoanRequest(LoanRequestModel request) {
    final items = getFilteredNavItems();
    final index = items.indexWhere((item) => item.route == '/loans');
    if (index != -1) {
      _selectedIndex = index;
      _clearSubViews();
      _selectedLoanRequest = request;
      notifyListeners();
    }
  }

  void navigateToLoanDetails(String loanId, String shareholderId) {
    final items = getFilteredNavItems();
    final index = items.indexWhere((item) => item.route == '/loans');
    if (index != -1) {
      _selectedIndex = index;
      _clearSubViews();
      _selectedLoanId = loanId;
      _selectedLoanShareholderId = shareholderId;
      notifyListeners();
    }
  }

  void _clearSubViews() {
    _selectedShareholderId = null;
    _selectedLoanRequest = null;
    _selectedLoanId = null;
    _selectedLoanShareholderId = null;
    _isApplyingLoan = false;
    _isViewingAdminSettings = false;
    _isReviewingLoanRequest = false;
    _loanInitialShareholder = null;
    _loanRequestIdToReview = null;
  }

  void clearShareholderSelection() {
    _selectedShareholderId = null;
    notifyListeners();
  }

  void clearLoanSelection() {
    _selectedLoanRequest = null;
    _selectedLoanId = null;
    _selectedLoanShareholderId = null;
    notifyListeners();
  }

  List<NavItemModel> getFilteredNavItems() {
    debugPrint('DEBUG: [NavigationViewModel] getFilteredNavItems for role: $_currentUserRole');
    if (_currentUserRole == null) return [];
    final items = _allItems.where((item) => item.allowedRoles.contains(_currentUserRole)).toList();
    debugPrint('DEBUG: [NavigationViewModel] Found ${items.length} items');
    return items;
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
