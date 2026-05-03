import '../models/user_model.dart';


class AuthorizationService {
  final UserRole _userRole;

  AuthorizationService(this._userRole);

  bool get canManageUsers => _userRole == UserRole.admin;
  bool get canManageInventory => [UserRole.admin, UserRole.cashier].contains(_userRole);
  bool get canViewReports => [UserRole.admin, UserRole.shareholder].contains(_userRole);
  bool get canProcessSales => [UserRole.admin, UserRole.cashier].contains(_userRole);
  bool get canModifySettings => _userRole == UserRole.admin;
  bool get canViewFinancials => [UserRole.admin, UserRole.shareholder].contains(_userRole);
  bool get canDeleteProducts => _userRole == UserRole.admin;
  bool get canEditProducts => [UserRole.admin, UserRole.cashier].contains(_userRole);

  bool canPerform(String action) {
    final permissions = _getPermissions();
    return permissions.contains(action);
  }

  Set<String> _getPermissions() {
    switch (_userRole) {
      case UserRole.admin:
        return {
          'manage_users', 'manage_inventory', 'view_reports',
          'process_sales', 'modify_settings', 'view_financials',
          'delete_products', 'edit_products',
        };
      case UserRole.cashier:
        return {'manage_inventory', 'process_sales', 'edit_products'};
      case UserRole.shareholder:
        return {'view_reports', 'view_financials'};
    }
  }
}