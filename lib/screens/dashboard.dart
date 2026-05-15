import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/loan_requests_viewmodel.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/shareholders_viewmodel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color mutedBrown = Color(0xFF8B7365);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color cardBorder = Color(0xFFE6DED8);
  static const Color backgroundColor = Color(0xFFFDFBFA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanRequestViewModel>().loadPendingRequests();
      context.read<ShareholderViewModel>().loadShareholders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loanVM = context.watch<LoanRequestViewModel>();
    final shareholderVM = context.watch<ShareholderViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: '₱');

    // Filter approved for Disbursed, but you may want to use a separate 
    // ApprovedLoansViewModel once you have one.
    final totalDisbursed = loanVM.pendingRequests
        .where((l) => l.status.toLowerCase() == 'approved')
        .fold(0.0, (sum, l) => sum + l.requestedAmount);

    final totalCustomersCount = shareholderVM.shareholders.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;
        final double horizontalPadding = isSmallScreen ? 16.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SearchBar removed here because it's now handled by AppShell header

              _buildSectionHeader("Reports Overview"),
              const SizedBox(height: 16),

              // KPI Cards Grid
              Row(
                children: [
                  _buildSummaryCard(
                    'Total Disbursed Loans', 
                    currencyFormat.format(totalDisbursed), 
                    Icons.account_balance_wallet_outlined
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    'Total Customers', 
                    totalCustomersCount.toString(), 
                    Icons.people_outline
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    'Current Interest Rate', 
                    '3.2%', 
                    Icons.timer_outlined
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionHeader("Revenue & Collection Trend"),
              const SizedBox(height: 16),
              _buildChartPlaceholder(),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader("Recent Loan Transactions"),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See all", 
                      style: TextStyle(color: terracotta, fontWeight: FontWeight.w600)
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _buildActivityTable(loanVM),
              const SizedBox(height: 40), // Bottom padding for scroll
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: terracotta),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: mutedBrown, fontSize: 13)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value, 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBrown)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: const Center(
        child: Text("Chart Visualizing Data Trends", style: TextStyle(color: mutedBrown)),
      ),
    );
  }

  Widget _buildActivityTable(LoanRequestViewModel viewModel) {
    final recentItems = viewModel.pendingRequests.take(5).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: DataTable(
              headingRowHeight: 50,
              headingRowColor: WidgetStateProperty.all(terracotta),
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
              rows: recentItems.map((loan) {
                return DataRow(cells: [
                  DataCell(Text(loan.id?.toString() ?? '-', style: const TextStyle(color: darkBrown))),
                  DataCell(Text(loan.borrower?.fullName ?? 'Unknown', style: const TextStyle(color: darkBrown))),
                  DataCell(Text(loan.formattedRequestedAmount, style: const TextStyle(color: darkBrown, fontWeight: FontWeight.w600))),
                  DataCell(_buildStatusBadge(loan.status)),
                  DataCell(Text(loan.formattedDate, style: const TextStyle(color: mutedBrown))),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isApproved = status.toLowerCase() == 'approved';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: isApproved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0), 
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isApproved ? const Color(0xFFC8E6C9) : const Color(0xFFFFCCBC)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isApproved ? const Color(0xFF2E7D32) : terracotta, 
          fontSize: 10, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}