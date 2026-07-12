import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/loan_request_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/loan_requests_table.dart';
import '../widgets/page_turner.dart';
import 'loan_evaluation_page.dart';
import 'loan_details_page.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanRequestViewModel>().fetchLoanRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationViewModel>();
    
    if (nav.selectedLoanRequest != null) {
      return LoanEvaluationPage(
        request: nav.selectedLoanRequest!,
        // Assuming LoanEvaluationPage might need a way to signal "back" 
        // if it's being used within this internal navigation
      );
    }

    if (nav.selectedLoanId != null) {
      return LoanDetailsPage(
        loanId: nav.selectedLoanId!,
        shareholderId: nav.selectedLoanShareholderId ?? '',
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Consumer<LoanRequestViewModel>(
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
                          child: LoanRequestsTable(
                            requests: viewModel.loanRequests,
                            isLoading: viewModel.isLoading && viewModel.loanRequests.isEmpty,
                            onView: (request) {
                              nav.navigateToLoanRequest(request);
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

  Widget _buildActionBar(LoanRequestViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Loan Management',
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
                label: 'Status',
                value: viewModel.statusFilter,
                items: ['All', 'Pending', 'Approved', 'Released', 'Rejected'],
                onChanged: (val) {
                  if (val != null) viewModel.setStatusFilter(val);
                },
              ),
              const SizedBox(width: 12),
              _buildFilterDropdown(
                label: 'Purpose',
                value: viewModel.purposeFilter,
                items: ['All', 'Educational', 'Medical', 'Emergency', 'Business', 'Others'],
                onChanged: (val) {
                  if (val != null) viewModel.setPurposeFilter(val);
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
