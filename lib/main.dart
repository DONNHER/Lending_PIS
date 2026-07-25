import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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
    CanteenApp(
      apiService: apiService,
      cacheService: cacheService,
      emailService: emailService,
    ),
  );
}

class CanteenApp extends StatelessWidget {

  final ApiService apiService;
  final LocalCacheService cacheService;
  final EmailService emailService;

  const CanteenApp({
    super.key,
    required this.apiService,
    required this.cacheService,
    required this.emailService,
  });


  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [

        // ================= SERVICES =================

        Provider<ApiService>.value(
          value: apiService,
        ),


        // ================= REPOSITORIES =================

        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            context.read<ApiService>(),
          ),
        ),

        Provider<StorageRepository>(
          create: (_) => StorageRepository(),
        ),

        Provider<ActivityLogRepository>(
          create: (_) => ActivityLogRepository(apiService),
        ),

        Provider<LendingRepository>(
          create: (_) => LendingRepository(apiService),
        ),

        Provider<ShareCapitalRepository>(
          create: (_) => ShareCapitalRepository(apiService),
        ),

        Provider<ShareholderRepository>(
          create: (_) => ShareholderRepository(apiService),
        ),

        Provider<TransactionRepository>(
          create: (_) => TransactionRepository(apiService),
        ),

        Provider<NotificationRepository>(
          create: (_) => NotificationRepository(apiService),
        ),

        Provider<UserRepository>(
          create: (_) => UserRepository(apiService),
        ),

        Provider<ConsignmentProductsRepository>(
          create: (_) => ConsignmentProductsRepository(apiService),
        ),

        Provider<DailyInventoryRepository>(
          create: (_) => DailyInventoryRepository(apiService),
        ),


        // ================= AUTH VIEWMODEL =================

        ChangeNotifierProvider<AuthViewModel>(
          create: (context) {

            final vm = AuthViewModel(
              context.read<AuthRepository>(),
              context.read<ActivityLogRepository>(),
              context.read<StorageRepository>(),
            );

            vm.restoreSession();

            return vm;
          },
        ),


        // ================= NAVIGATION =================

        ChangeNotifierProxyProvider<AuthViewModel, NavigationViewModel>(
          create: (_) => NavigationViewModel(),

          update: (context, auth, nav) {

            if(auth.isAuthenticated &&
                auth.currentUser != null) {

              if(nav!.currentUserRole !=
                  auth.currentUser!.role) {

                nav.setUserRole(
                  auth.currentUser!.role,
                );
              }
            }

            return nav!;
          },
        ),


        // ================= ADD SHAREHOLDER =================

        ChangeNotifierProvider<AddShareholderViewModel>(
          create: (context) =>
              AddShareholderViewModel(
                shareholderRepository:
                context.read<ShareholderRepository>(),

                storageRepository:
                context.read<StorageRepository>(),

                authRepository:
                context.read<AuthRepository>(),

                emailService:
                emailService,
              ),
        ),


        // ================= ADMIN DASHBOARD =================

        ChangeNotifierProxyProvider<AuthViewModel, DashboardViewModel>(
          create: (context) =>
              DashboardViewModel(
                context.read<LendingRepository>(),
                context.read<ShareholderRepository>(),
                context.read<TransactionRepository>(),
              ),

          update: (context, auth, model) {

            if(auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.admin &&
                model != null &&
                !model.isInitialized) {

              model.initDashboard();
            }

            return model!;
          },
        ),


        ChangeNotifierProxyProvider<AuthViewModel, LoanRequestViewModel>(
          create: (context) =>
              LoanRequestViewModel(
                context.read<LendingRepository>(),
              ),

          update: (context, auth, model) {

            if(auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.admin &&
                model != null &&
                !model.isInitialized) {

              model.fetchLoanRequests();
            }

            return model!;
          },
        ),


        ChangeNotifierProxyProvider<AuthViewModel, ShareholderViewModel>(
          create: (context) =>
              ShareholderViewModel(
                context.read<ShareholderRepository>(),
              ),

          update: (context, auth, model) {

            if(auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.admin &&
                model != null &&
                !model.isInitialized) {

              model.fetchShareholders();
            }

            return model!;
          },
        ),


        ChangeNotifierProxyProvider<AuthViewModel, UserManagementViewModel>(
          create: (context) =>
              UserManagementViewModel(
                context.read<UserRepository>(),
              ),

          update: (context, auth, model) {

            if(auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.admin &&
                model != null &&
                !model.isInitialized) {

              model.fetchUsers();
            }

            return model!;
          },
        ),


        ChangeNotifierProxyProvider<AuthViewModel, TransactionViewModel>(
          create: (context) =>
              TransactionViewModel(
                context.read<TransactionRepository>(),
              ),

          update: (context, auth, model) {

            if(auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.admin &&
                model != null &&
                !model.isInitialized) {

              model.fetchTransactions();
            }

            return model!;
          },
        ),
        // ================= SHARE CAPITAL =================

        ChangeNotifierProxyProvider<AuthViewModel, ShareCapitalViewModel>(
          create: (context) => ShareCapitalViewModel(
            context.read<ShareholderRepository>(),
            context.read<TransactionRepository>(),
            context.read<LendingRepository>(),
          ),

          update: (context, auth, model) {
            if (auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.shareholder &&
                auth.currentUser?.id != null &&
                model != null) {

              model.setUserId(auth.currentUser!.id!);
            }

            return model!;
          },
        ),
       // ================= SHAREHOLDER TRANSACTION =================
        ChangeNotifierProxyProvider<AuthViewModel, ShareholderTransactionViewModel>(
          create: (context) => ShareholderTransactionViewModel(
            context.read<TransactionRepository>(),
            context.read<ShareholderRepository>(),
            context.read<LendingRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.shareholder &&
                auth.currentUser?.id != null &&
                model != null &&
                !model.isInitialized) {
              model.setUserId(auth.currentUser!.id!);
            }
            return model!;
          },
        ),


        // ================= NOTIFICATION =================

        ChangeNotifierProvider<NotificationViewModel>(
          create: (context) =>
              NotificationViewModel(
                context.read<NotificationRepository>(),
              ),
        ),

        ChangeNotifierProxyProvider<AuthViewModel, ActivityLogViewModel>(
          create: (context) =>
              ActivityLogViewModel(
                context.read<ActivityLogRepository>(),
              ),

          update: (context, auth, model) {

            if(auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.admin &&
                model != null &&
                !model.isInitialized) {

              model.fetchLogs();
            }

            return model!;
          },
        ),


        ChangeNotifierProxyProvider<AuthViewModel, UpdateInterestViewModel>(
          create: (context) =>
              UpdateInterestViewModel(
                context.read<LendingRepository>(),
              ),

          update: (context, auth, model) {

            if(auth.isAuthenticated &&
                auth.currentUser?.role == UserRole.admin &&
                model != null &&
                !model.isInitialized) {

              model.loadData();
            }

            return model!;
          },
        ),


        // ================= OTHER VIEWMODELS =================

        ChangeNotifierProvider(
          create: (context)=>
              LoanDetailsViewModel(
                context.read<LendingRepository>(),
                context.read<TransactionRepository>(),
                context.read<ShareholderRepository>(),
              ),
        ),


        ChangeNotifierProvider(
          create: (context)=>
              ShareholderDetailViewModel(
                context.read<ShareholderRepository>(),
              ),
        ),


        ChangeNotifierProvider(
          create: (_) =>
              ImportExportViewModel(apiService),
        ),


        ChangeNotifierProvider(
          create: (_) =>
              ConsignmentProductsViewModel(),
        ),


        ChangeNotifierProvider(
          create: (context)=>
              ConsignmentDetailViewModel(
                context.read<ConsignmentProductsRepository>(),
                context.read<DailyInventoryRepository>(),
              ),
        ),


        ChangeNotifierProvider(
          create: (_) =>
              ConsigneeDetailViewModel(),
        ),


        ChangeNotifierProvider(
          create: (_) =>
              ConsigneeViewModel(),
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
  bool _isVerifyingRecovery = false;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _handleInitialSessionForRecovery();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          if (data.event == AuthChangeEvent.passwordRecovery) {
            if (!mounted) return;

            setState(() {
              _hasRecoveryRedirect = true;
              _isVerifyingRecovery = false;
            });
          }
        });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }


  Future<void> _handleInitialSessionForRecovery() async {
    try {
      final uri = Uri.base;

      final code = uri.queryParameters['code'];

      final isRecovery =
          code != null || uri.fragment.contains('type=recovery');


      if (!isRecovery) {
        setState(() {
          _isVerifyingRecovery = false;
        });
        return;
      }


      setState(() {
        _isVerifyingRecovery = true;
      });


      // PKCE recovery flow
      if (code != null) {
        await Supabase.instance.client.auth.exchangeCodeForSession(code);
      }


      if (!mounted) return;


      setState(() {
        _hasRecoveryRedirect = true;
        _isVerifyingRecovery = false;
      });


    } catch (e) {
      debugPrint(
        'Recovery session error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isVerifyingRecovery = false;
        _hasRecoveryRedirect = false;
      });
    }
  }


  void _clearRecovery() {
    if (!mounted) return;

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

      home: _getHome(auth),

      routes: {

        '/login': (context) =>
        const LoginPage(),

        '/admin-login': (context) =>
        const AdminLoginPage(),

        '/register': (context) =>
        const RegistrationPage(),


        '/dashboard': (context) =>
            _protectedRouteGuard(
              auth,
              const AppShell(),
              UserRole.admin,
            ),


        '/users': (context) =>
            _protectedRouteGuard(
              auth,
              const AppShell(),
              UserRole.admin,
            ),


        '/shareholder-dashboard': (context) =>
            _protectedRouteGuard(
              auth,
              const AppLayout(),
              UserRole.shareholder,
            ),


        '/notifications': (context) =>
            _protectedRouteGuard(
              auth,
              const NotificationScreen(),
              null,
            ),

      },
    );
  }



  Widget _getHome(AuthViewModel auth) {


    if (_isVerifyingRecovery) {

      return const Scaffold(
        backgroundColor: Color(0xFFFDF8F5),
        body: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [

              CircularProgressIndicator(
                color: Color(0xFFC06C4D),
              ),

              SizedBox(height:24),

              Text(
                'Preparing password recovery...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

            ],
          ),
        ),
      );
    }



    if (_hasRecoveryRedirect) {

      return ChangePasswordPage(
        onPasswordChanged: _clearRecovery,
      );

    }



    if (!auth.isInitialized) {

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );

    }



    if (!auth.isAuthenticated) {

      return const LoginPage();

    }



    if (auth.isImpersonating) {

      return const AppShell();

    }



    if (auth.currentUser?.role ==
        UserRole.shareholder) {

      return const AppLayout();

    }



    return Consumer<DashboardViewModel>(
      builder: (context, dashboard, child) {

        if (!dashboard.isInitialized) {

          return const Scaffold(
            backgroundColor:
            Color(0xFFFDF8F5),

            body: Center(
              child:
              CircularProgressIndicator(
                color:
                Color(0xFFC06C4D),
              ),
            ),
          );

        }


        return const AppShell();

      },
    );
  }
  Widget _protectedRouteGuard(
      AuthViewModel auth,
      Widget targetScreen,
      UserRole? requiredRole,
      ) {

    if (!auth.isInitialized || _isVerifyingRecovery) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF8F5),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFC06C4D),
          ),
        ),
      );
    }


    if (!auth.isAuthenticated) {
      return const LoginPage();
    }


    if (requiredRole != null &&
        auth.currentUser?.role != requiredRole &&
        !auth.isImpersonating) {

      return Scaffold(
        backgroundColor: const Color(0xFFFDF8F5),
        body: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.lock_outline,
                size:48,
                color:Color(0xFFC06C4D),
              ),

              const SizedBox(height:16),

              const Text(
                'Access Denied',
                style:TextStyle(
                  fontSize:20,
                  fontWeight:FontWeight.bold,
                ),
              ),

              const SizedBox(height:24),

              ElevatedButton(
                onPressed: () {

                  final route =
                      auth.dashboardRoute ?? '/login';

                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(
                    route,
                        (route)=>false,
                  );
                },

                child:
                const Text(
                  'Return to Dashboard',
                ),
              ),
            ],
          ),
        ),
      );
    }


    return targetScreen;
  }
}