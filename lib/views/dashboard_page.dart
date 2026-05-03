import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/kpi_card.dart';
import '../widgets/bar_chart.dart';
import '../widgets/recent_sales_list.dart';
import '../widgets/low_stock_alerts.dart';
import '../widgets/dashboard_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(),
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
          backgroundColor: AppTheme.surface,
          body: SafeArea(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(child: DashboardHeader(
                greeting: viewModel.greeting,
                currentDate: viewModel.currentDate,
                selectedPeriod: viewModel.selectedPeriod,
                onPeriodChanged: viewModel.setPeriod,
              )),
              SliverToBoxAdapter(child: _buildKpiRow(context, viewModel)),
              SliverToBoxAdapter(child: _buildChartSection(viewModel)),
              SliverToBoxAdapter(child: _buildBottomRow(context, viewModel)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildKpiRow(BuildContext context, DashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth > 500 ? 1.5 : 1.6,
          children: viewModel.kpiCards.map((kpi) => KpiCard(data: kpi)).toList(),
        );
      }),
    );
  }

  Widget _buildChartSection(DashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withOpacity(0.12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Weekly Sales', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
              SizedBox(height: 2),
              Text('Revenue per day (₱)', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text('This Week', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary))),
          ]),
          const SizedBox(height: 24),
          SizedBox(height: 160, child: BarChart(bars: viewModel.weeklySales)),
        ]),
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context, DashboardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: RecentSalesList(recentSales: viewModel.recentSales)),
            const SizedBox(width: 12),
            SizedBox(width: 260, child: LowStockAlerts(lowStockItems: viewModel.lowStockItems)),
          ]);
        }
        return Column(children: [
          RecentSalesList(recentSales: viewModel.recentSales),
          const SizedBox(height: 12),
          LowStockAlerts(lowStockItems: viewModel.lowStockItems),
        ]);
      }),
    );
  }
}