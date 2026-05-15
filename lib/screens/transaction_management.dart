import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/lending_viewmodel/transactions_viewmodel.dart';
import '../models/lending_models/transaction.dart';

class TransactionManagementPage extends StatefulWidget {
  const TransactionManagementPage({super.key});

  @override
  State<TransactionManagementPage> createState() => _TransactionManagementPageState();
}

class _TransactionManagementPageState extends State<TransactionManagementPage> {
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color accentPeach = Color(0xFFF5E6DA);
  static const Color borderLine = Color(0xFFE6DED8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsViewModel>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TransactionsViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;
        final double horizontalPadding = isSmallScreen ? 12.0 : 24.0;

        return Column(
          children: [
            // 1. Header with Filters (Responsive)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
              child: isSmallScreen
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton(null, "Type"),
                        const SizedBox(width: 8),
                        _buildFilterButton(null, "Status"),
                        const SizedBox(width: 8),
                        _buildActionOutlineButton(Icons.refresh_rounded, "Refresh", () => viewModel.loadTransactions()),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      _buildFilterButton(null, "Type"),
                      const SizedBox(width: 8),
                      _buildFilterButton(null, "Status"),
                      const SizedBox(width: 8),
                      _buildFilterButton(null, "Date"),
                      const Spacer(),
                      _buildActionOutlineButton(Icons.refresh_rounded, "Refresh", () => viewModel.loadTransactions()),
                      const SizedBox(width: 8),
                      _buildActionOutlineButton(Icons.upload_outlined, "Export", () {}),
                    ],
                  ),
            ),

            // 2. The Data Table (Responsive Scroll)
            Expanded(
              child: _buildBody(viewModel, horizontalPadding, isSmallScreen),
            ),

            // 3. Footer
            _buildFooter(viewModel, horizontalPadding, isSmallScreen),
          ],
        );
      },
    );
  }

  Widget _buildBody(TransactionsViewModel viewModel, double hPadding, bool isSmall) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: terracotta));
    }

    final transactions = viewModel.transactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage ?? "No transactions recorded yet."),
          ],
        ),
      );
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
              columnSpacing: isSmall ? 16 : 24,
              headingRowHeight: 56,
              headingRowColor: WidgetStateProperty.all(terracotta),
              columns: const [
                DataColumn(label: Text('Type', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Reference', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Amount', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Date', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
              ],
              rows: transactions.map((t) => _buildTransactionRow(t)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildTransactionRow(TransactionEntry tx) {
    final currencyFormat = NumberFormat.currency(symbol: '₱');
    final dateFormat = DateFormat('MMM dd, yyyy');
    final bool isCredit = tx.type.toString().toLowerCase().contains('payment') || 
                          tx.type.toString().toLowerCase().contains('contribution');
    final Color amountColor = isCredit ? Colors.green.shade700 : Colors.red.shade700;

    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) return accentPeach;
        return Colors.white;
      }),
      cells: [
        DataCell(_buildTypeBadge(tx.type)),
        DataCell(Text(tx.referenceId, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        DataCell(Text(
          "${isCredit ? '+' : '-'}${currencyFormat.format(tx.amount)}",
          style: TextStyle(fontWeight: FontWeight.bold, color: amountColor),
        )),
        DataCell(Text(dateFormat.format(tx.date))), 
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.print_outlined, size: 18, color: darkBrown), onPressed: () {}),
            IconButton(icon: const Icon(Icons.chevron_right, size: 18, color: darkBrown), onPressed: () {}),
          ],
        )),
      ],
    );
  }

  Widget _buildTypeBadge(TransactionType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: darkBrown.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(type.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: darkBrown)),
    );
  }

  Widget _buildFooter(TransactionsViewModel viewModel, double hPadding, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isSmall) Text("Showing ${viewModel.transactions.length} records", style: const TextStyle(color: Colors.grey)),
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

  Widget _buildFilterButton(IconData? icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(border: Border.all(color: borderLine), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [if(icon != null) Icon(icon, size: 16), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 13)), const Icon(Icons.keyboard_arrow_down, size: 16)]),
  );

  Widget _buildActionOutlineButton(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
    onPressed: onTap, icon: Icon(icon, size: 16, color: darkBrown), label: Text(label, style: const TextStyle(color: darkBrown, fontSize: 13)),
    style: OutlinedButton.styleFrom(side: const BorderSide(color: borderLine), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
  );
}
