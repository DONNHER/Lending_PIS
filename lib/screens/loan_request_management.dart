import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ViewModels & Models
import 'package:capstone_application/viewmodels/lending_viewmodel/loan_requests_viewmodel.dart';
import 'package:capstone_application/models/lending_models/loan_request.dart';
// Partials
import 'package:capstone_application/screens/partials/custom_pagination_footer.dart';

class LoanRequestManagementPage extends StatefulWidget {
  const LoanRequestManagementPage({super.key});

  @override
  State<LoanRequestManagementPage> createState() => _LoanRequestManagementPageState();
}

class _LoanRequestManagementPageState extends State<LoanRequestManagementPage> {
  // Brand Colors
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color borderLine = Color(0xFFE6DED8);
  static const Color darkText = Color(0xFF3A2318);
  static const Color hoverColor = Color(0xFFF5E6DA);
  static const Color backgroundPeach = Color(0xFFFDFBFA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanRequestViewModel>().loadPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoanRequestViewModel>();

    return Scaffold(
      backgroundColor: backgroundPeach,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double hPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. HEADER FILTERS & ACTIONS ────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 16),
                child: Row(
                  children: [
                    _buildHeaderFilter(Icons.filter_list_rounded, "Status"),
                    const SizedBox(width: 8),
                    _buildHeaderFilter(Icons.calendar_today_outlined, "Date Range"),
                    const Spacer(),
                    _buildActionOutlineButton(Icons.refresh_rounded, "Refresh", () {
                       viewModel.loadPendingRequests();
                    }),
                    const SizedBox(width: 8),
                    _buildNewLoanButton(),
                  ],
                ),
              ),

              // ── 2. DATA TABLE AREA ────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: _buildDataTableContainer(viewModel),
                ),
              ),

              // ── 3. PAGINATION FOOTER ──────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: borderLine)),
                ),
                child: CustomPaginationFooter(
                  currentPage: 1, 
                  totalRows: viewModel.pendingRequests.length, 
                  rowsPerPage: 10,
                  onPageChanged: (page) {
                    // viewModel.fetchPage(page);
                  },
                  onRowsPerPageChanged: (value) {
                    // viewModel.updateRowsPerPage(value);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDataTableContainer(LoanRequestViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: terracotta));
    }

    if (viewModel.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No loan requests found.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1000), 
            child: DataTable(
              headingRowHeight: 56,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              headingRowColor: WidgetStateProperty.all(terracotta),
              horizontalMargin: 20,
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text('ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Client Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Principal Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Int. Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Applied On', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
              rows: viewModel.pendingRequests.map((req) => _buildLoanRow(req)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildLoanRow(LoanRequestModel req) {
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) return hoverColor;
        return Colors.white;
      }),
      cells: [
        DataCell(Text("#${req.id}", style: const TextStyle(color: Colors.grey, fontSize: 13))),
        DataCell(Text(req.borrower?.fullName ?? 'Unknown', 
          style: const TextStyle(fontWeight: FontWeight.w600, color: darkText))),
        DataCell(Text(req.formattedRequestedAmount, 
          style: const TextStyle(fontWeight: FontWeight.bold, color: darkText))),
        DataCell(_buildStatusBadge(req.status)),
        DataCell(const Text("3.2%", style: TextStyle(color: darkText))),
        DataCell(Text(req.formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionIcon(Icons.edit_outlined, Colors.blueGrey, () {}),
            _buildActionIcon(Icons.delete_outline, Colors.redAccent, () {}),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        )),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isApproved = status.toLowerCase() == 'approved';
    Color baseColor = isApproved ? const Color(0xFF2E7D32) : terracotta;
    Color bgColor = isApproved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    Color borderColor = isApproved ? const Color(0xFFC8E6C9) : const Color(0xFFFFCCBC);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: baseColor, 
          fontSize: 10, 
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeaderFilter(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: darkText),
      label: Row(
        children: [
          Text(label, style: const TextStyle(color: darkText, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        ],
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: borderLine),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildActionOutlineButton(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
    onPressed: onTap, 
    icon: Icon(icon, size: 16, color: darkText), 
    label: Text(label, style: const TextStyle(color: darkText, fontSize: 13)),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: borderLine), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  Widget _buildNewLoanButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 18),
      label: const Text("New Loan", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: terracotta,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}