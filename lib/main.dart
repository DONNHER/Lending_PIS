import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/services/api_service.dart';
import 'package:capstone_application/services/local_cache_service.dart';
import 'package:capstone_application/repositories/auth_repository.dart';
import 'package:capstone_application/repositories/consignee_repository.dart';
import 'package:capstone_application/repositories/consignment_repository.dart';
import 'package:capstone_application/repositories/product_repository.dart';
import 'package:capstone_application/repositories/storage_repository.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/share_capital_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/activity_log_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/repositories/notification_repository.dart';
import 'package:capstone_application/repositories/daily_inventory_repository.dart';
import 'package:capstone_application/repositories/grocery_repository.dart';
import 'package:capstone_application/repositories/consignment_products_repository.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/viewmodels/add_shareholder_viewmodel.dart';
import 'package:capstone_application/viewmodels/consignee_detail_viewmodel.dart';
import 'package:capstone_application/viewmodels/consignee_viewmodel.dart';
import 'package:capstone_application/viewmodels/consignment_products_viewmodels.dart';
import 'package:capstone_application/viewmodels/notification_viewmodel.dart';
import 'package:capstone_application/viewmodels/share_capital_viewmodel.dart';
import 'package:capstone_application/viewmodels/shareholder_transaction_viewmodel.dart';
import 'package:capstone_application/viewmodels/consignment_detail_viewmodel.dart';
import 'package:capstone_application/viewmodels/grocery_viewmodel.dart';
import 'package:capstone_application/viewmodels/dashboard_viewmodel.dart';
import 'package:capstone_application/viewmodels/loan_request_viewmodel.dart';
import 'package:capstone_application/viewmodels/shareholder_viewmodel.dart';
import 'package:capstone_application/viewmodels/transaction_viewmodel.dart';
import 'package:capstone_application/viewmodels/activity_log_viewmodel.dart';
import 'package:capstone_application/viewmodels/navigation_viewmodel.dart';
import 'package:capstone_application/viewmodels/update_interest_viewmodel.dart';
import 'package:capstone_application/views/login_page.dart';
import 'package:capstone_application/views/registration_page.dart';
import 'package:capstone_application/views/app_shell.dart';
import 'package:capstone_application/views/ShareHolder_screens/layouts/app.dart';
import 'package:capstone_application/views/ShareHolder_screens/notification.dart';
import 'package:capstone_application/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  final apiBaseUrl = dotenv.env['API_URL'] ?? 'https://lending-pis-1.onrender.com/api';
  final apiService = ApiService(baseUrl: apiBaseUrl);
  final cacheService = LocalCacheService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<LocalCacheService>.value(value: cacheService),
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

    return MultiProvider(
      providers: [
        // ─── Repositories ──────
        Provider(create: (_) => AuthRepository(apiService)),
        Provider(create: (_) => ConsigneeRepository(apiService)),
        Provider(create: (_) => ConsignmentRepository(apiService)),
        Provider(create: (_) => StorageRepository()), // 🚀 Fixed: Removed const
        Provider(create: (_) => ConsignmentProductsRepository(apiService)),
        Provider(create: (_) => ProductRepository(apiService)),
        Provider(create: (_) => DailyInventoryRepository(apiService)),
        Provider(create: (_) => GroceryRepository(apiService)),
        Provider(create: (_) => ActivityLogRepository(apiService)),
        Provider(create: (_) => LendingRepository(apiService)),
        Provider(create: (_) => ShareCapitalRepository(apiService)),
        Provider(create: (_) => ShareholderRepository(apiService)),
        Provider(create: (_) => TransactionRepository(apiService)),
        Provider(create: (_) => NotificationRepository(apiService)),

        // ─── ViewModels ────────────────────────────────────────────
        ChangeNotifierProvider(
          create: (context) {
            final authVM = AuthViewModel(
              context.read<AuthRepository>(), 
              context.read<ActivityLogRepository>(),
              context.read<StorageRepository>(),
            );
            
            // 🚀 Hook global unauthorized callback to trigger logout/redirect
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
          create: (context) => ConsigneeViewModel(
            repository: context.read<ConsigneeRepository>(),
            storageRepository: context.read<StorageRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ConsignmentProductsViewModel(
            context.read<ConsignmentProductsRepository>(),
            context.read<ProductRepository>(),
            context.read<ConsigneeRepository>(),
            context.read<StorageRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => GroceryViewModel(context.read<GroceryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AddShareholderViewModel(
            shareholderRepository: context.read<ShareholderRepository>(),
            storageRepository: context.read<StorageRepository>(),
            authRepository: context.read<AuthRepository>(),
          ),
        ),

        // ─── Admin Management ViewModels (Only for Admin role) ───────
        ChangeNotifierProxyProvider<AuthViewModel, DashboardViewModel>(
          create: (context) => DashboardViewModel(
            context.read<LendingRepository>(),
            context.read<ShareholderRepository>(),
            cacheService: cacheService,
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
            cacheService: cacheService,
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
            cacheService: cacheService,
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

        ChangeNotifierProxyProvider<AuthViewModel, TransactionViewModel>(
          create: (context) => TransactionViewModel(
            context.read<TransactionRepository>(),
            cacheService: cacheService,
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
            cacheService: cacheService,
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
            cacheService: cacheService,
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

        // ─── Shareholder Personal ViewModels (Only for Shareholder role) ─────
        ChangeNotifierProxyProvider<AuthViewModel, ShareCapitalViewModel>(
          create: (context) => ShareCapitalViewModel(
            context.read<ShareholderRepository>(),
            context.read<TransactionRepository>(),
            context.read<LendingRepository>(),
            cacheService: cacheService,
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
            context.read<ShareholderRepository>(),
            cacheService: cacheService,
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && auth.currentUser?.role == UserRole.shareholder) {
              model?.fetchData(userId: auth.currentUser!.id);
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
            cacheService: cacheService,
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && auth.currentUser?.role == UserRole.shareholder) {
              model?.fetchData(userId: auth.currentUser!.id);
            } else if (!auth.isAuthenticated) {
              model?.reset();
            }
            return model!;
          },
        ),
        
        ChangeNotifierProvider(
          create: (context) => ConsigneeDetailViewModel(
            consigneeRepository: context.read<ConsigneeRepository>(),
            consignmentRepository: context.read<ConsignmentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ConsignmentDetailViewModel(
            context.read<ConsignmentProductsRepository>(),
            context.read<DailyInventoryRepository>(),
          ),
        ),
      ],
      child: const RootApp(),
    );
  }
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return MaterialApp(
      title: 'Engr Canteen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getHome(auth),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/dashboard': (context) => const AppShell(),
        '/pos': (context) => const AppShell(),
        '/users': (context) => const AppShell(),
        '/shareholder-dashboard': (context) => const AppLayout(),
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }

  Widget _getHome(AuthViewModel auth) {
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

    // Role-based home redirection
    return auth.currentUser?.role == UserRole.shareholder 
        ? const AppLayout() 
        : const AppShell();
  }
}
