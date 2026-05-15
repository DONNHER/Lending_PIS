import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/funds_viewmodel.dart';
import 'package:intl/intl.dart';

class FundManagementPage extends StatefulWidget {
  const FundManagementPage({super.key});

  @override
  State<FundManagementPage> createState() => _FundManagementPageState();
}

class _FundManagementPageState extends State<FundManagementPage> {
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color accentPeach = Color(0xFFF5E6DA);
  static const Color borderLine = Color(0xFFE6DED8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FundManagementViewModel>().loadFundStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FundManagementViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: '₱');

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;
        final double horizontalPadding = isSmallScreen ? 12.0 : 24.0;

        return Column(
          children: [
            // 1. Top Section: Filters and Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
              child: isSmallScreen
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton("Source"),
                        const SizedBox(width: 8),
                        _buildActionOutlineButton(Icons.refresh_rounded, "Sync", () {
                          viewModel.loadFundStatus();
                        }),
                        const SizedBox(width: 8),
                        _buildAddFundButton(true),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      _buildFilterButton("Fund Source"),
                      const SizedBox(width: 8),
                      _buildFilterButton("Status"),
                      const Spacer(),
                      _buildActionOutlineButton(Icons.refresh_rounded, "Refresh", () {
                        viewModel.loadFundStatus();
                      }),
                      const SizedBox(width: 8),
                      _buildAddFundButton(false),
                    ],
                  ),
            ),

            // 2. Fund Summary Metrics (Responsive)
            if (viewModel.summary != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                child: _buildMetricsRow(viewModel.summary!, isSmallScreen, currencyFormat),
              ),

            // 3. Fund Data Table (Responsive Scroll)
            Expanded(
              child: _buildBody(viewModel, horizontalPadding, isSmallScreen),
            ),

            // 4. Footer
            _buildFooter(horizontalPadding, isSmallScreen),
          ],
        );
      },
    );
  }

  Widget _buildMetricsRow(FundSummary summary, bool isSmall, NumberFormat format) {
    if (isSmall) {
      return Column(
        children: [
          _metricCard("Available", format.format(summary.availableBalance), Colors.green),
          const SizedBox(height: 8),
          _metricCard("Disbursed", format.format(summary.totalDisbursed), terracotta),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _metricCard("Total Capital", format.format(summary.totalCapital), darkBrown)),
        const SizedBox(width: 12),
        Expanded(child: _metricCard("Available", format.format(summary.availableBalance), Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _metricCard("Disbursed", format.format(summary.totalDisbursed), terracotta)),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBody(FundManagementViewModel viewModel, double hPadding, bool isSmall) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: terracotta));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderLine),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 20,
              columnSpacing: 20,
              headingRowHeight: 56,
              headingRowColor: WidgetStateProperty.all(terracotta),
              columns: const [
                DataColumn(label: Text('Fund ID', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Source', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Status', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
              ],
              rows: [
                _buildFundRow("FND-001", "Eleanor Vance", "₱ 50,000.00", "Active"),
                _buildFundRow("FND-002", "General Reserve", "₱ 100,000.00", "Idle"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildFundRow(String id, String source, String total, String status) {
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) return accentPeach;
        return Colors.white;
      }),
      cells: [
        DataCell(Text(id)),
        DataCell(Text(source, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(total, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(_buildStatusBadge(status)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.green), onPressed: () {}),
            IconButton(icon: const Icon(Icons.chevron_right, size: 18, color: darkBrown), onPressed: () {}),
          ],
        )),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == "Active" ? const Color(0xFF10B981) : (status == "Idle" ? Colors.blueGrey : terracotta);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFooter(double hPadding, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.chevron_left, size: 18, color: Colors.grey),
              SizedBox(width: 16),
              Icon(Icons.chevron_right, size: 18, color: darkBrown),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(border: Border.all(color: borderLine), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [Text(label, style: const TextStyle(fontSize: 13)), const Icon(Icons.keyboard_arrow_down, size: 16)]),
  );

  Widget _buildActionOutlineButton(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
    onPressed: onTap, icon: Icon(icon, size: 16, color: darkBrown), label: Text(label, style: const TextStyle(color: darkBrown, fontSize: 13)),
    style: OutlinedButton.styleFrom(side: const BorderSide(color: borderLine)),
  );

  Widget _buildAddFundButton(bool isSmall) => ElevatedButton.icon(
    onPressed: () {}, icon: const Icon(Icons.add, size: 16, color: Colors.white), label: Text(isSmall ? "Add" : "Add Capital", style: const TextStyle(color: Colors.white)),
    style: ElevatedButton.styleFrom(backgroundColor: terracotta),
  );
}
