import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/transaction_table.dart';
import '../widgets/page_turner.dart';
import '../widgets/transaction_detail_dialog.dart';
import '../widgets/import_export_buttons.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionViewModel>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
            'Transactions',
            style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
        ),
        actions: [
          Consumer<TransactionViewModel>(
            builder: (context, viewModel, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
              onPressed: viewModel.refresh,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<TransactionViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              // 🚀 Thin Loading Indicator right below the App Bar header
              if (viewModel.isLoading)
                const LinearProgressIndicator(
                  color: Color(0xFFC06C4D),
                  backgroundColor: Color(0xFFFDF8F5),
                  minHeight: 3,
                )
              else
                const SizedBox(height: 3),

              _buildActionBar(viewModel),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: TransactionTable(
                            transactions: viewModel.transactions,
                            isLoading: viewModel.isLoading,
                            onView: (tx) {
                              showDialog(
                                context: context,
                                builder: (context) => TransactionDetailDialog(transaction: tx),
                              );
                            },
                          ),
                        ),
                        PageTurner(
                          currentPage: viewModel.currentPage,
                          totalPages: viewModel.lastPage,
                          totalRows: viewModel.totalRows,
                          rowsPerPage: viewModel.rowsPerPage,
                          onPageChanged: viewModel.setPage,
                          onRowsPerPageChanged: (val) {
                            if (val != null) viewModel.setRowsPerPage(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionBar(TransactionViewModel viewModel) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterDropdown(
                        label: 'Type',
                        value: viewModel.typeFilter,
                        items: ['All', 'Disbursement', 'Payment', 'Contribution'],
                        onChanged: (val) {
                          if (val != null) viewModel.setTypeFilter(val);
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildFilterDropdown(
                        label: 'Status',
                        value: viewModel.statusFilter,
                        items: ['All', 'Successful', 'Pending', 'Failed'],
                        onChanged: (val) {
                          if (val != null) viewModel.setStatusFilter(val);
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildFilterDropdown(
                        label: 'Sort By',
                        value: viewModel.sortOrder,
                        items: ['Newest', 'Oldest', 'Highest Amount', 'Lowest Amount'],
                        onChanged: (val) {
                          if (val != null) viewModel.setSortOrder(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  ImportExportButtons(
                    type: 'transactions',
                    onRefresh: viewModel.refresh,
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            items: items.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}