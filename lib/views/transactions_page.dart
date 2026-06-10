import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../widgets/page_turner.dart';
import '../widgets/transaction_table.dart';
import 'ShareHolder_screens/details_page/repayment_details.dart';
import 'loan_details_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  @override
  void initState() {
    super.initState();
    // Ensure data is fetched if not already initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<TransactionViewModel>();
      if (!viewModel.isInitialized) {
        viewModel.fetchTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _TransactionsBody();
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
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Transactions', 
              style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
                onPressed: () => viewModel.fetchTransactions(forceRefresh: true),
                tooltip: 'Refresh Transactions',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => viewModel.fetchTransactions(forceRefresh: true),
              color: const Color(0xFFC06C4D),
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
                        child: viewModel.isLoading && viewModel.transactions.isEmpty
                            ? const Center(
                                child: CircularProgressIndicator(color: Color(0xFFC06C4D)),
                              )
                            : viewModel.errorMessage != null && viewModel.transactions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                                      const SizedBox(height: 16),
                                      Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
                                      TextButton(
                                        onPressed: () => viewModel.fetchTransactions(forceRefresh: true),
                                        child: const Text('Try Again'),
                                      )
                                    ],
                                  ),
                                )
                              : TransactionTable(
                                  transactions: viewModel.transactions,
                                  onView: (tx) {
                                    // 🚀 HANDLE CLICKS:
                                    if (tx.type.contains('Disbursement') && tx.referenceId.isNotEmpty) {
                                      // Navigate to Loan Details
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LoanDetailsPage(
                                            loanId: tx.referenceId,
                                            shareholderId: tx.shareholderId ?? '',
                                          ),
                                        ),
                                      );
                                    } else if (tx.type.contains('Payment') || tx.type.contains('Repayment')) {
                                      // Navigate to Repayment Details (The Receipt View)
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RepaymentDetailsScreen(transaction: tx),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Transaction Detail: ${tx.type} - ${tx.amount}')),
                                      );
                                    }
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
