import '../models/user_model.dart';

class RoleBasedRouter {
  static String getDashboardRoute(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/dashboard';
      case UserRole.cashier:
        return '/pos';
      case UserRole.shareholder:
        return '/dashboard';
    }
  }

  static bool hasAccess(UserRole role, String routeName) {
    final allowedRoutes = getAllowedRoutes(role);
    return allowedRoutes.contains(routeName);
  }

  static List<String> getAllowedRoutes(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return ['/dashboard', '/pos', '/consignment-products', '/grocery-products', 
                '/consignees', '/sales', '/inventory', '/shareholders', 
                '/reports', '/cashiers', '/profile'];
      case UserRole.cashier:
        return ['/pos', '/products', '/grocery-products', 
                '/sales', '/inventory', '/profile'];
      case UserRole.shareholder:
        return ['/dashboard', '/sales', '/shareholders', 
                '/reports', '/profile'];
    }
  }
}