import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Lending Specific Imports
import 'package:capstone_application/repositories/lending_repository/logs_repository.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/logs_viewmodel.dart';
import 'package:capstone_application/repositories/lending_repository/transactions_repository.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/transactions_viewmodel.dart';
import 'package:capstone_application/repositories/lending_repository/shareholders_repository.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/shareholders_viewmodel.dart';
import 'package:capstone_application/repositories/lending_repository/dashboard_repository.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/dashboard_viewmodel.dart';
import 'package:capstone_application/repositories/lending_repository/loan_requests_repository.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/loan_requests_viewmodel.dart';
import 'package:capstone_application/repositories/lending_repository/loans_repository.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/funds_viewmodel.dart';

// Existing Imports
import 'app_theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/daily_inventory_repository.dart';
import 'repositories/grocery_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/navigation_viewmodel.dart';
import 'views/app_shell.dart';
import 'views/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://frrbgxtnsymfuuwttgfg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZycmJneHRuc3ltZnV1d3R0Z2ZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyNzcxMjksImV4cCI6MjA5Mjg1MzEyOX0.8ALKJysrUiojUuP7o_lcOUjtZDf0HglzmguC8nvnCkM',
  );

  runApp(const CanteenApp());
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;

    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository(supabaseClient)),
        Provider(create: (_) => GroceryRepository(supabaseClient)),
        Provider(create: (_) => DailyInventoryRepository(supabaseClient)),
        Provider(create: (_) => ActivityRepository(supabaseClient)),
        Provider(create: (_) => TransactionsRepository(supabaseClient)),
        Provider(create: (_) => ShareholderRepository(supabaseClient)),
        Provider(create: (_) => DashboardRepository(supabaseClient)),
        Provider(create: (_) => LoanRequestRepository(supabaseClient)),
        Provider(create: (_) => LoanRepository(supabaseClient)),

        ChangeNotifierProvider(
          create: (context) => AuthViewModel(context.read<AuthRepository>())..restoreSession(),
        ),
        
        // Safer ProxyProvider implementation
        ChangeNotifierProxyProvider<AuthViewModel, NavigationViewModel>(
          create: (context) => NavigationViewModel(),
          update: (context, auth, previousNav) {
            final nav = previousNav ?? NavigationViewModel();
            // Sync role whenever auth state changes
            if (auth.status == AuthStatus.authenticated && auth.currentUser != null) {
              nav.setUserRole(auth.currentUser!.role);
            } else {
              nav.setUserRole(null);
            }
            return nav;
          },
        ),

        ChangeNotifierProvider(
          create: (context) => DashboardViewModel(
            dashboardRepository: context.read<DashboardRepository>(),
            loanRepository: context.read<LoanRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => LoanRequestViewModel(context.read<LoanRequestRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => TransactionsViewModel(transactionsRepository: context.read<TransactionsRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ShareholderViewModel(repository: context.read<ShareholderRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ActivityLogsViewModel(
            loanRepository: context.read<LoanRepository>(),
            transactionRepository: context.read<TransactionsRepository>(),
            shareholderRepository: context.read<ShareholderRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FundManagementViewModel(
            dashboardRepository: context.read<DashboardRepository>(),
            transactionRepository: context.read<TransactionsRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Canteen App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthViewModel>(
          builder: (context, auth, _) {
            if (auth.status == AuthStatus.authenticated) {
              return const AppShell();
            } else if (auth.status == AuthStatus.loading) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            } else {
              return const LoginPage();
            }
          },
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/dashboard': (context) => const AppShell(),
        },
      ),
    );
  }
}
