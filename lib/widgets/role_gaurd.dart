import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/role_based_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_model.dart';

/// Widget that guards child content based on user role
class RoleGuard extends StatelessWidget {
  final Widget child;
  final List<UserRole>? allowedRoles;
  final String? requiredPermission;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.child,
    this.allowedRoles,
    this.requiredPermission,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    
    if (!authViewModel.isAuthenticated || authViewModel.currentUser == null) {
      return fallback ?? const _UnauthorizedWidget(message: 'Please log in to access this feature');
    }

    final userRole = authViewModel.currentUser!.role;

    // Check role-based access
    if (allowedRoles != null && !allowedRoles!.contains(userRole)) {
      return fallback ?? _UnauthorizedWidget(
        message: 'You do not have permission to access this feature',
        userRole: userRole,
      );
    }

    // Check permission-based access
    if (requiredPermission != null) {
      final authService = authViewModel.authorizationService;
      if (!authService!.canPerform(requiredPermission!)) {
        return fallback ?? _UnauthorizedWidget(
          message: 'You do not have the required permission for this action',
          userRole: userRole,
        );
      }
    }

    return child;
  }
}

class _UnauthorizedWidget extends StatelessWidget {
  final String message;
  final UserRole? userRole;

  const _UnauthorizedWidget({
    required this.message,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (userRole != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Current role: ${userRole!.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (userRole != null) {
                    final dashboardRoute = RoleBasedRouter.getDashboardRoute(userRole!);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      dashboardRoute,
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}