import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/services/local_cache_service.dart';
import 'package:capstone_application/services/email_service.dart';
import 'package:capstone_application/repositories/auth_repository.dart';
import 'package:capstone_application/repositories/storage_repository.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/share_capital_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/repositories/notification_repository.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/viewmodels/add_shareholder_viewmodel.dart';
import 'package:capstone_application/viewmodels/notification_viewmodel.dart';
import 'package:capstone_application/viewmodels/share_capital_viewmodel.dart';
import 'package:capstone_application/viewmodels/shareholder_transaction_viewmodel.dart';
import 'package:capstone_application/viewmodels/dashboard_viewmodel.dart';
import 'package:capstone_application/viewmodels/loan_request_viewmodel.dart';
import 'package:capstone_application/viewmodels/shareholder_viewmodel.dart';
import 'package:capstone_application/viewmodels/transaction_viewmodel.dart';
import 'package:capstone_application/viewmodels/activity_log_viewmodel.dart';
import 'package:capstone_application/viewmodels/navigation_viewmodel.dart';
import 'package:capstone_application/viewmodels/update_interest_viewmodel.dart';
import 'package:capstone_application/viewmodels/loan_details_viewmodel.dart';
import 'package:capstone_application/repositories/consignment_products_repository.dart';
import 'package:capstone_application/repositories/daily_inventory_repository.dart';
import 'package:capstone_application/viewmodels/consignment_products_viewmodels.dart';
import 'package:capstone_application/viewmodels/consignment_detail_viewmodel.dart';
import 'package:capstone_application/viewmodels/consignee_detail_viewmodel.dart';
import 'package:capstone_application/viewmodels/consignee_viewmodel.dart';
import 'package:capstone_application/views/login_page.dart';
import 'package:capstone_application/views/admin_login_page.dart';
import 'package:capstone_application/views/registration_page.dart';
import 'package:capstone_application/views/app_shell.dart';
import 'package:capstone_application/views/change_password_page.dart';
import 'package:capstone_application/views/ShareHolder_screens/layouts/app.dart';
import 'package:capstone_application/views/ShareHolder_screens/notification.dart';
import 'package:capstone_application/models/user_model.dart';

import 'package:capstone_application/viewmodels/shareholder_detail_viewmodel.dart';

import 'package:capstone_application/viewmodels/user_management_viewmodel.dart';
import 'package:capstone_application/repositories/user_repository.dart';
import 'package:capstone_application/viewmodels/import_export_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  }

  final apiBaseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000/api';
  final apiService = ApiService(baseUrl: apiBaseUrl);
  final cacheService = LocalCacheService();
  final emailService = EmailService(apiService);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<LocalCacheService>.value(value: cacheService),
        Provider<EmailService>.value(value: emailService),
      ],
      child: const CanteenApp(),
    ),
  );
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<ApiService>();
    final cacheService = context.read<LocalCacheService>();
    final emailService = context.read<EmailService>();

    return MultiProvider(
      providers: [
        // ─── Repositories ──────
        Provider(create: (_) => AuthRepository(apiService)),
        Provider(create: (_) => StorageRepository()),
        Provider(create: (_) => ActivityLogRepository(apiService)),
        Provider(create: (_) => LendingRepository(apiService)),
        Provider(create: (_) => ShareCapitalRepository(apiService)),
        Provider(create: (_) => ShareholderRepository(apiService)),
        Provider(create: (_) => TransactionRepository(apiService)),
        Provider(create: (_) => NotificationRepository(apiService)),
        Provider(create: (_) => UserRepository(apiService)),
        Provider(create: (_) => ConsignmentProductsRepository(apiService)),
        Provider(create: (_) => DailyInventoryRepository(apiService)),

        // ─── ViewModels ────────────────────────────────────────────
        ChangeNotifierProvider(
          create: (context) {
            final authVM = AuthViewModel(
              context.read<AuthRepository>(), 
              context.read<ActivityLogRepository>(),
              context.read<StorageRepository>(),
            );
            
            apiService.onUnauthorized = authVM.handleUnauthorized;
            authVM.restoreSession();
            return authVM;
          },
        ),
        ChangeNotifierProxyProvider<AuthViewModel, NavigationViewModel>(
          create: (context) => NavigationViewModel(),
          update: (context, auth, nav) {
            if (auth.isAuthenticated && auth.currentUser != null) {
              if (nav!.currentUserRole != auth.currentUser!.role) {
                nav.setUserRole(auth.currentUser!.role);
              }
            }
            return nav!;
          },
        ),
        ChangeNotifierProvider(
          create: (context) => AddShareholderViewModel(
            shareholderRepository: context.read<ShareholderRepository>(),
            storageRepository: context.read<StorageRepository>(),
            authRepository: context.read<AuthRepository>(),
            emailService: emailService,
          ),
        ),

        // ─── Admin Management ViewModels (Only for Admin role) ───────
        ChangeNotifierProxyProvider<AuthViewModel, DashboardViewModel>(
          create: (context) => DashboardViewModel(
            context.read<LendingRepository>(),
            context.read<ShareholderRepository>(),
            context.read<TransactionRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && 
                auth.currentUser?.role == UserRole.admin && 
                model != null && !model.isInitialized) {
              model.initDashboard();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, LoanRequestViewModel>(
          create: (context) => LoanRequestViewModel(
            context.read<LendingRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && 
                auth.currentUser?.role == UserRole.admin && 
                model != null && !model.isInitialized) {
              model.fetchLoanRequests();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, ShareholderViewModel>(
          create: (context) => ShareholderViewModel(
            context.read<ShareholderRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && 
                auth.currentUser?.role == UserRole.admin && 
                model != null && !model.isInitialized) {
              model.fetchShareholders();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, UserManagementViewModel>(
          create: (context) => UserManagementViewModel(
            context.read<UserRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && 
                auth.currentUser?.role == UserRole.admin && 
                model != null && !model.isInitialized) {
              model.fetchUsers();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, TransactionViewModel>(
          create: (context) => TransactionViewModel(
            context.read<TransactionRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && 
                auth.currentUser?.role == UserRole.admin && 
                model != null && !model.isInitialized) {
              model.fetchTransactions();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, ActivityLogViewModel>(
          create: (context) => ActivityLogViewModel(
            context.read<ActivityLogRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && 
                auth.currentUser?.role == UserRole.admin && 
                model != null && !model.isInitialized) {
              model.fetchLogs();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, UpdateInterestViewModel>(
          create: (context) => UpdateInterestViewModel(
            context.read<LendingRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && 
                auth.currentUser?.role == UserRole.admin && 
                model != null && !model.isInitialized) {
              model.loadData();
            }
            return model!;
          },
        ),

        // 🚀 Registered with all 3 required repositories
        ChangeNotifierProvider(
          create: (context) => LoanDetailsViewModel(
            context.read<LendingRepository>(),
            context.read<TransactionRepository>(),
            context.read<ShareholderRepository>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => ShareholderDetailViewModel(
            context.read<ShareholderRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ImportExportViewModel(apiService),
        ),
        ChangeNotifierProvider(create: (_) => ConsignmentProductsViewModel()),
        ChangeNotifierProvider(
          create: (context) => ConsignmentDetailViewModel(
            context.read<ConsignmentProductsRepository>(),
            context.read<DailyInventoryRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => ConsigneeDetailViewModel()),
        ChangeNotifierProvider(create: (_) => ConsigneeViewModel()),

        // ─── Shareholder Personal ViewModels (Only for Shareholder role) ─────
        ChangeNotifierProxyProvider<AuthViewModel, ShareCapitalViewModel>(
          create: (context) => ShareCapitalViewModel(
            context.read<ShareholderRepository>(),
            context.read<TransactionRepository>(),
            context.read<LendingRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && auth.currentUser?.role == UserRole.shareholder) {
              model?.setUserId(auth.currentUser!.id);
            } else if (!auth.isAuthenticated) {
              model?.reset();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, NotificationViewModel>(
          create: (context) => NotificationViewModel(
            context.read<NotificationRepository>(),
          ),
          update: (context, auth, model) {
            final shareholderId = auth.currentUser?.shareholder?.id;
            if (auth.isAuthenticated && shareholderId != null) {
              model?.loadNotifications(shareholderId: shareholderId);
            } else if (!auth.isAuthenticated) {
              model?.reset();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, ShareholderTransactionViewModel>(
          create: (context) => ShareholderTransactionViewModel(
            context.read<TransactionRepository>(),
            context.read<ShareholderRepository>(),
            context.read<LendingRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && auth.currentUser?.role == UserRole.shareholder) {
              model?.setUserId(auth.currentUser!.id);
            } else if (!auth.isAuthenticated) {
              model?.reset();
            }
            return model!;
          },
        ),
      ],
      child: const RootApp(),
    );
  }
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool _hasRecoveryRedirect = false;

  @override
  void initState() {
    super.initState();
    _handleInitialSessionForRecovery();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        setState(() {
          _hasRecoveryRedirect = true;
        });
      }
    });
  }

  Future<void> _handleInitialSessionForRecovery() async {
    try {
      final uri = Uri.base;
      final fragment = uri.fragment;
      if (fragment.contains('type=recovery') || uri.queryParameters.containsKey('code')) {
        setState(() {
          _hasRecoveryRedirect = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking initial recovery URI: $e');
    }
  }

  // 🚀 Add this method to clear the flag after password change / cancel
  void _clearRecovery() {
    setState(() {
      _hasRecoveryRedirect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return MaterialApp(
      navigatorKey: AuthViewModel.navigatorKey,
      title: 'Lending System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 🚀 Pass the clear callback down to ChangePasswordPage
      home: _hasRecoveryRedirect
          ? ChangePasswordPage(onPasswordChanged: _clearRecovery)
          : _getHome(auth),
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/dashboard': (context) => const AppShell(),
        '/users': (context) => const AppShell(),
        '/shareholder-dashboard': (context) => const AppLayout(),
        '/notifications': (context) => const NotificationScreen(),
        '/change-password': (context) => const ChangePasswordPage(),
      },
    );
  }

  Widget _getHome(AuthViewModel auth) {
    if (_hasRecoveryRedirect) {
      return ChangePasswordPage(onPasswordChanged: _clearRecovery);
    }
    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC06C4D)),
        ),
      );
    }
    if (!auth.isAuthenticated) {
      return const LoginPage();
    }
    if (auth.isImpersonating) {
      return const AppShell();
    }
    if (auth.currentUser?.role == UserRole.shareholder) {
      return const AppLayout();
    }

    return Consumer<DashboardViewModel>(
      builder: (context, dashboard, child) {
        if (!dashboard.isInitialized) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDF8F5),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFC06C4D)),
                  const SizedBox(height: 24),
                  const Text(
                    'Synchronizing your dashboard...',
                    style: TextStyle(
                      color: Color(0xFF32211A),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const AppShell();
      },
    );
  }
}