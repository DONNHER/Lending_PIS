import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/lending_repository.dart';
import '../viewmodels/loan_request_viewmodel.dart';
import '../widgets/page_turner.dart';
import '../widgets/loan_requests_table.dart';
import 'add_loan_page.dart';
import 'loan_evaluation_page.dart';
import 'loan_approval_page.dart';
import 'loan_details_page.dart';

class LoansPage extends StatelessWidget {
  final String? shareholderId;

  const LoansPage({
    super.key,
    this.shareholderId,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 Uses the global LoanRequestViewModel provided in main.dart
    return const _LoansBody();
  }
}

class _LoansBody extends StatefulWidget {
  const _LoansBody();

  @override
  State<_LoansBody> createState() => _LoansBodyState();
}

class _LoansBodyState extends State<_LoansBody> {
  @override
  void initState() {
    super.initState();
    // Ensure data is loaded if this is the first time or context changed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<LoanRequestViewModel>();
      vm.fetchLoanRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoanRequestViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, viewModel),
                if (viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  ),
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
                      child: Stack(
                        children: [
                          LoanRequestsTable(
                            loanRequests: viewModel.loanRequests,
                            onView: (req) {
                              Widget destinationPage;
                              final status = req.status.toString().toLowerCase();

                              if (status.contains('pending')) {
                                destinationPage = LoanEvaluationPage(request: req);
                              }
                              else if (status.contains('approved')) {
                                destinationPage = LoanApprovalPage(initialRequest: req);
                              }
                              else {
                                destinationPage = LoanDetailsPage(loanId: req.id, shareholderId: req.shareholderId);
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => destinationPage),
                              ).then((_) => viewModel.fetchLoanRequests(forceRefresh: true));
                            },
                          ),
                          // 🚀 Only show full loading if initialized for the first time
                          if (viewModel.isLoading && !viewModel.isInitialized)
                            Container(
                              color: Colors.white.withOpacity(0.6),
                              child: const Center(
                                child: CircularProgressIndicator(color: Color(0xFFC06C4D)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                PageTurner(
                  currentPage: viewModel.currentPage,
                  totalPages: viewModel.totalPages,
                  totalRows: viewModel.totalRows,
                  rowsPerPage: viewModel.rowsPerPage,
                  onPageChanged: (page) => viewModel.setPage(page),
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

  Widget _buildHeader(BuildContext context, LoanRequestViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (viewModel.filteredShareholderId != null) ...[
                InputChip(
                  label: const Text('Filtered Shareholder'),
                  onDeleted: () => viewModel.clearShareholderFilter(),
                  deleteIconColor: Colors.white,
                  backgroundColor: const Color(0xFFC06C4D),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
              ],
              _buildFilterButton(
                context: context,
                label: viewModel.selectedStatus == null ? 'All' : viewModel.selectedStatus!,
                options: [
                  'All',
                  'Active',
                  'Pending',
                  'Approved',
                  'Released',
                  'Rejected',
                  'Fully Paid',
                ],
                onSelected: (val) => viewModel.setStatus(val == 'All' ? null : val),
              ),
              const SizedBox(width: 12),
              _buildAmountSortMenu(viewModel),
              const SizedBox(width: 12),
              _buildDateSortMenu(viewModel),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (viewModel.filteredShareholderId != null) ...[
                IconButton(
                  tooltip: 'Back to Profile',
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF32211A)),
                  onPressed: () => Navigator.maybePop(context),
                  style: IconButton.styleFrom(
                    hoverColor: const Color(0xFF32211A).withOpacity(0.04),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddLoanPage()),
                  ).then((_) => viewModel.fetchLoanRequests(forceRefresh: true));
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Loan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC06C4D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  minimumSize: const Size(0, 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSortMenu(LoanRequestViewModel viewModel) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'high') {
          viewModel.setSortByAmount(lowestFirst: false);
        } else if (value == 'low') {
          viewModel.setSortByAmount(lowestFirst: true);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'high', child: Text('Highest amount first')),
        PopupMenuItem(value: 'low', child: Text('Lowest amount first')),
      ],
      child: _filterMenuTrigger(
        icon: Icons.money,
        label: viewModel.sortByAmountLabel,
      ),
    );
  }

  Widget _buildDateSortMenu(LoanRequestViewModel viewModel) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'newest') {
          viewModel.setSortByDate(oldestFirst: false);
        } else if (value == 'oldest') {
          viewModel.setSortByDate(oldestFirst: true);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'newest', child: Text('Newest first')),
        PopupMenuItem(value: 'oldest', child: Text('Oldest first')),
      ],
      child: _filterMenuTrigger(
        icon: Icons.calendar_today_outlined,
        label: viewModel.sortByDateLabel,
      ),
    );
  }

  Widget _filterMenuTrigger({required IconData icon, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textDark),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textDark),
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
