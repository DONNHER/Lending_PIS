import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/lending_repository.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../widgets/kpi_card.dart';
import '../widgets/lending_bar_chart.dart';
import '../widgets/recent_loans_table.dart';
import '../widgets/dashboard_header.dart';
import 'loan_payment_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardBody();
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().initDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Dashboard', 
              style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
                onPressed: () => viewModel.refreshData(),
                tooltip: 'Refresh Dashboard',
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: viewModel.isLoading
                  ? const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      color: Color(0xFFC06C4D),
                    )
                  : const SizedBox(height: 2),
            ),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => viewModel.refreshData(),
              color: const Color(0xFFC06C4D),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DashboardHeader(
                      greeting: viewModel.greeting,
                      currentDate: viewModel.currentDate,
                      searchResults: viewModel.searchResults,
                      onSearch: viewModel.setSearchQuery,
                      onResultTap: (shareholder) {
                        if (shareholder == null) return;
                        viewModel.setSearchQuery('');
                        context.read<NavigationViewModel>().navigateToShareholder(shareholder.id);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: _buildSectionTitle('Reports Overview')),
                  SliverToBoxAdapter(child: _buildKpiRow(context, viewModel)),
                  
                  SliverToBoxAdapter(child: _buildSectionTitle('Revenue & Collection Trend')),
                  SliverToBoxAdapter(child: _buildChartSection(viewModel)),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: _buildRecentLoansSection(context, viewModel),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, DashboardViewModel viewModel) {
    if (viewModel.isLoading && viewModel.kpiCards.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D), strokeWidth: 3)),
      );
    }

    if (viewModel.kpiCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: viewModel.kpiCards.asMap().entries.map((entry) {
          final kpi = entry.value;
          final isLast = entry.key == viewModel.kpiCards.length - 1;
          
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: isLast ? 0 : 8,
              ),
              child: KpiCard(
                data: kpi,
                onTap: kpi.label == 'Users' 
                  ? () {
                      final nav = context.read<NavigationViewModel>();
                      final items = nav.getFilteredNavItems();
                      final index = items.indexWhere((item) => item.route == '/users');
                      if (index != -1) {
                        nav.navigateTo(index);
                      }
                    }
                  : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(DashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Performance Metrics',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab(viewModel, ChartFilter.week, 'Week'),
                      _buildFilterTab(viewModel, ChartFilter.month, 'Month'),
                      _buildFilterTab(viewModel, ChartFilter.year, 'Year'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230),
              child: viewModel.isChartLoading && viewModel.chartData.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D), strokeWidth: 3))
                  : LendingBarChart(data: viewModel.chartData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLoansSection(BuildContext context, DashboardViewModel viewModel) {
    if (viewModel.isLoading && viewModel.recentTransactions.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D), strokeWidth: 3)),
      );
    }

    return RecentLoansTable(
      transactions: viewModel.recentTransactions,
      onTap: (tx) async {
        debugPrint('DEBUG: Dashboard tapping transaction: ${tx.id}, Type: ${tx.type}, Shareholder: ${tx.shareholderId}');
        
        final repo = context.read<LendingRepository>();
        final nav = context.read<NavigationViewModel>();
        final String? refId = tx.referenceId;
        final String? shareholderId = tx.shareholderId;

        // 1. If it's a Loan Disbursement, go to Loan Details
        if (tx.type.contains('Disbursement') && refId != null && refId.isNotEmpty) {
          if (!context.mounted) return;
          nav.navigateToLoanDetails(refId, shareholderId ?? '');
          return;
        }

        // 2. If it's a Loan Payment, go to Loan Payment Page
        if (tx.type.contains('Payment') && refId != null && refId.isNotEmpty) {
          if (!context.mounted) return;
          context.read<NavigationViewModel>().navigateToLoanPayment(loanId: refId);
          return;
        }
        
        // 3. If it's a Capital Contribution or something else, go to Shareholder Details
        if (shareholderId != null && shareholderId.isNotEmpty) {
          debugPrint('DEBUG: Navigating to Shareholder Details for: $shareholderId');
          if (!context.mounted) return;
          nav.navigateToShareholder(shareholderId);
          return;
        }

        // Fallback: try to see if it's a loan request ID
        final String targetId = (refId != null && refId.isNotEmpty) ? refId : tx.id;
        final fullRequest = await repo.getLoanRequestById(targetId);
            
        if (fullRequest != null && context.mounted) {
          nav.navigateToLoanRequest(fullRequest);
        }
      },
      onSeeAll: () {
        final nav = context.read<NavigationViewModel>();
        final items = nav.getFilteredNavItems();
        final index = items.indexWhere((item) => item.route == '/transactions');
        if (index != -1) {
          nav.navigateTo(index);
        }
      },
    );
  }

  Widget _buildFilterTab(DashboardViewModel viewModel, dynamic filter, String label) {
    final isSelected = viewModel.selectedFilter == filter;
    return GestureDetector(
      onTap: () => viewModel.setChartFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC06C4D) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
