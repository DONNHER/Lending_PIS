import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../widgets/kpi_card.dart';
import '../widgets/lending_bar_chart.dart';
import '../widgets/recent_loans_table.dart';
import '../widgets/dashboard_header.dart';
import 'loan_evaluation_page.dart';
import 'loan_details_page.dart';
import 'loan_payment_page.dart';
import 'shareholder_detail_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardViewModel(
        context.read<LendingRepository>(),
        context.read<ShareholderRepository>(),
      ),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          body: SafeArea(
            child: Stack(
              children: [
                RefreshIndicator(
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

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShareholderDetailPage(
                                  shareholderId: shareholder.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildSectionTitle('Reports Overview')),
                      SliverToBoxAdapter(child: _buildKpiRow(viewModel)),
                      SliverToBoxAdapter(child: _buildSectionTitle('Revenue & Collection Trend')),
                      SliverToBoxAdapter(child: _buildChartSection(viewModel)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        sliver: SliverToBoxAdapter(
                          child: RecentLoansTable(
                            transactions: viewModel.recentTransactions,
                            onTap: (tx) async {
                              final repo = context.read<LendingRepository>();
                              if (tx.type == 'Loan Disbursement' && tx.referenceId.isNotEmpty) {
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoanDetailsPage(
                                      loanId: tx.referenceId,
                                      shareholderId: tx.shareholderId ?? '',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (tx.type == 'Loan Payment' && tx.referenceId.isNotEmpty) {
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoanPaymentPage(loanId: tx.referenceId),
                                  ),
                                );
                                return;
                              }
                              final fullRequest = tx.referenceId.isNotEmpty
                                  ? await repo.getLoanRequestById(tx.referenceId)
                                  : await repo.getLoanRequestById(tx.id);
                              if (fullRequest != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoanEvaluationPage(request: fullRequest),
                                  ),
                                );
                              }
                            },
                            onSeeAll: () {
                              final nav = context.read<NavigationViewModel>();
                              final items = nav.getFilteredNavItems();
                              final index = items.indexWhere((item) => item.route == '/loans');
                              if (index != -1) {
                                nav.navigateTo(index);
                              }
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
                if (viewModel.isLoading)
                  Container(
                    color: Colors.white.withOpacity(0.6),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFFC06C4D)),
                    ),
                  ),
              ],
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

  Widget _buildKpiRow(DashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        return Row(
          children: List<Widget>.from(
            viewModel.kpiCards.map((kpi) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: KpiCard(data: kpi),
                ),
              );
            }),
          ),
        );
      }),
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
              child: LendingBarChart(data: viewModel.chartData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(DashboardViewModel viewModel, ChartFilter filter, String label) {
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
