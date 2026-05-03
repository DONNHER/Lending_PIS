import 'package:capstone_application/repositories/consignee_repository.dart';
import 'package:capstone_application/repositories/consignment_products_repository.dart';
import 'package:capstone_application/repositories/consignment_repository.dart';
import 'package:capstone_application/repositories/product_repository.dart';
import 'package:capstone_application/repositories/storage_repository.dart';
import 'package:capstone_application/viewmodels/consignee_detail_viewmodel.dart';
import 'package:capstone_application/viewmodels/consignee_viewmodel.dart';
import 'package:capstone_application/viewmodels/consignment_products_viewmodels.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/daily_inventory_repository.dart';
import 'repositories/grocery_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/consignment_detail_viewmodel.dart';
import 'viewmodels/grocery_viewmodel.dart';
import 'views/login_page.dart';
import 'views/registration_page.dart';
import 'views/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://frrbgxtnsymfuuwttgfg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZycmJneHRuc3ltZnV1d3R0Z2ZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyNzcxMjksImV4cCI6MjA5Mjg1MzEyOX0.8ALKJysrUiojUuP7o_lcOUjtZDf0HglzmguC8nvnCkM',
  );

  runApp(const CanteenApp());
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;
    final authRepository = AuthRepository(supabaseClient);
    final consigneeRepository = ConsigneeRepository(supabaseClient);
    final consignmentRepository = ConsignmentRepository(supabaseClient);
    final storageRepository = StorageRepository(supabaseClient);
    final consignmentProductsRepository = ConsignmentProductsRepository(
      supabaseClient,
    );
    final productRepository = ProductRepository(supabaseClient);
    final dailyInventoryRepository = DailyInventoryRepository(supabaseClient);
    final groceryRepository = GroceryRepository(supabaseClient);
    
    return MultiProvider(
      providers: [
        // ─── ViewModels ────────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(
          create: (_) => ConsigneeViewModel(
            repository: consigneeRepository,
            storageRepository: storageRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ConsigneeDetailViewModel(
            consigneeRepository: consigneeRepository,
            consignmentRepository: consignmentRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ConsignmentProductsViewModel(
            consignmentProductsRepository,
            productRepository,
            consigneeRepository,
            storageRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ConsignmentDetailViewModel(
            consignmentProductsRepository,
            dailyInventoryRepository,
          ),
        ),
        ChangeNotifierProvider(
  create: (_) => GroceryViewModel(groceryRepository),
),

        // ─── Repositories (for other services that need them) ──────
        Provider.value(value: authRepository),
        Provider.value(value: consigneeRepository),
        Provider.value(value: consignmentRepository),
        Provider.value(value: storageRepository),
        Provider.value(value: consignmentProductsRepository),
        Provider.value(value: productRepository),
        Provider.value(value: dailyInventoryRepository),
        Provider.value(value: groceryRepository),
      ],
      child: MaterialApp(
        title: 'Engr Canteen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegistrationPage(),
          '/dashboard': (context) => const AppShell(),
          '/pos': (context) => const AppShell(),
        },
      ),
    );
  }
}
