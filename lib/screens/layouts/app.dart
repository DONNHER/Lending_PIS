import 'package:flutter/material.dart';
import 'navigation.dart';
import '../dashboard.dart';
import '../user_management.dart';
import '../transaction_management.dart';
import '../loan_request_management.dart';
import '../fund_management.dart';
import '../activity_logs.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // This controller manages the link between the Tabs and the Content
    return DefaultTabController(
      length: 6, 
      child: Scaffold(
        // 1. The "Include": Calling the Navigation widget from the other file
        // We put it in a Column so it stays fixed at the top
        body: Column(
          children: [
            const CustomNavigation(), // This is your layouts/navigation.dart widget
            
            // 2. The "Slot": This fills the rest of the screen with content
            const Expanded(
              child: TabBarView(
                children: [
                  DashboardPage(),
                  UserManagementPage(),
                  TransactionManagementPage(),
                  LoanRequestManagementPage(),
                  FundManagementPage(),
                  ActivityLogsPage()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}