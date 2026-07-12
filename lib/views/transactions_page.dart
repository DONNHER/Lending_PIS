import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/transaction_table.dart';
import '../widgets/page_turner.dart';
import '../widgets/transaction_detail_dialog.dart';

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
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<TransactionViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
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
                          color: Colors.black.withOpacity(0.02),
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
                            isLoading: viewModel.isLoading && viewModel.transactions.isEmpty,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const Spacer(),
              IconButton(
                onPressed: viewModel.refresh,
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
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
        ],
      ),
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
