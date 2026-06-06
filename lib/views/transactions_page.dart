import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/transaction_repository.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../widgets/page_turner.dart';
import '../widgets/transaction_table.dart';
import 'loan_payment_page.dart';
import 'loan_details_page.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TransactionViewModel(context.read<TransactionRepository>()),
      child: const _TransactionsBody(),
    );
  }
}

class _TransactionsBody extends StatelessWidget {
  const _TransactionsBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, viewModel),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: TransactionTable(
                        transactions: viewModel.transactions,
                        onView: (tx) async {
                          if (tx.type == 'Loan Disbursement' && tx.referenceId.isNotEmpty) {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoanDetailsPage(loanId: tx.referenceId,shareholderId: tx.shareholderId ?? '',),
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

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No detail view for type: ${tx.type}')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                PageTurner(
                  currentPage: viewModel.currentPage,
                  totalPages: viewModel.totalPages,
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
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TransactionViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildFilterButton(
                context: context,
                label: viewModel.selectedStatus == 'All' ? 'Status' : viewModel.selectedStatus,
                options: ['All', 'Successful', 'Pending', 'Failed'],
                onSelected: viewModel.setStatus,
              ),
              const SizedBox(width: 12),
              _buildFilterButton(
                context: context,
                label: 'Date',
                options: ['All', 'Today', 'This Week', 'This Month'],
                onSelected: (val) {},
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Export'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textDark,
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              minimumSize: const Size(0, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required BuildContext context,
    required String label,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) => options.map((opt) => PopupMenuItem(value: opt, child: Text(opt))).toList(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textDark),
          ],
        ),
      ),
    );
  }
}
