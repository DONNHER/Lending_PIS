import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'services/api_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/consignee_repository.dart';
import 'repositories/consignment_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/storage_repository.dart';
import 'repositories/lending_repository.dart';
import 'repositories/share_capital_repository.dart';
import 'repositories/shareholder_repository.dart';
import 'repositories/activity_log_repository.dart';
import 'repositories/transaction_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/daily_inventory_repository.dart';
import 'repositories/grocery_repository.dart';
import 'repositories/consignment_products_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/add_shareholder_viewmodel.dart';
import 'viewmodels/consignee_detail_viewmodel.dart';
import 'viewmodels/consignee_viewmodel.dart';
import 'viewmodels/consignment_products_viewmodels.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'viewmodels/share_capital_viewmodel.dart';
import 'viewmodels/shareholder_transaction_viewmodel.dart';
import 'viewmodels/consignment_detail_viewmodel.dart';
import 'viewmodels/grocery_viewmodel.dart';
import 'views/login_page.dart';
import 'views/registration_page.dart';
import 'views/app_shell.dart';
import 'views/ShareHolder_screens/layouts/app.dart';
import 'views/ShareHolder_screens/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase from .env
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Initialize Laravel API Service from .env
  final apiBaseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000/api';
  final apiService = ApiService(baseUrl: apiBaseUrl);

  runApp(
    Provider<ApiService>.value(
      value: apiService,
      child: const CanteenApp(),
    ),
  );
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<ApiService>();

    return MultiProvider(
      providers: [
        // ─── Repositories ──────
        Provider(create: (_) => AuthRepository(apiService)),
        Provider(create: (_) => ConsigneeRepository(apiService)),
        Provider(create: (_) => ConsignmentRepository(apiService)),
        Provider(create: (_) => StorageRepository(apiService)), 
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
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(), 
            context.read<ActivityLogRepository>(),
            context.read<StorageRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ConsigneeViewModel(
            repository: context.read<ConsigneeRepository>(),
            storageRepository: context.read<StorageRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ConsigneeDetailViewModel(
            consigneeRepository: context.read<ConsigneeRepository>(),
            consignmentRepository: context.read<ConsignmentRepository>(),
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
          create: (context) => ConsignmentDetailViewModel(
            context.read<ConsignmentProductsRepository>(),
            context.read<DailyInventoryRepository>(),
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

        // ─── Shareholder ViewModels with ProxyProvider ────────────────
        ChangeNotifierProxyProvider<AuthViewModel, ShareCapitalViewModel>(
          create: (context) => ShareCapitalViewModel(
            context.read<ShareholderRepository>(),
            context.read<TransactionRepository>(),
            context.read<LendingRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && model != null) {
              model.fetchData();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, NotificationViewModel>(
          create: (context) => NotificationViewModel(
            context.read<NotificationRepository>(),
            context.read<ShareholderRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && model != null) {
              model.fetchData();
            }
            return model!;
          },
        ),

        ChangeNotifierProxyProvider<AuthViewModel, ShareholderTransactionViewModel>(
          create: (context) => ShareholderTransactionViewModel(
            context.read<TransactionRepository>(),
            context.read<ShareholderRepository>(),
          ),
          update: (context, auth, model) {
            if (auth.isAuthenticated && model != null) {
              model.fetchData();
            }
            return model!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Lending',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegistrationPage(),
          '/dashboard': (context) => const AppShell(),
          '/pos': (context) => const AppShell(),
          '/shareholder-dashboard': (context) => const AppLayout(),
          '/notifications': (context) => const NotificationScreen(),
        },
      ),
    );
  }
}
