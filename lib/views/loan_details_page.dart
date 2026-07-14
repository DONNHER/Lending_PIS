import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/viewmodels/loan_details_viewmodel.dart';
import 'package:capstone_application/views/loan_payment_page.dart';
import 'package:capstone_application/views/shareholder_detail_page.dart';

class LoanDetailsPage extends StatefulWidget {
  final String loanId;
  final String shareholderId;
  final VoidCallback? onBack;

  const LoanDetailsPage({
    super.key,
    required this.loanId,
    required this.shareholderId,
    this.onBack,
  });

  @override
  State<LoanDetailsPage> createState() => _LoanDetailsPageState();
}

class _LoanDetailsPageState extends State<LoanDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanDetailsViewModel>().fetchLoanDetails(widget.loanId);
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryBrown = Color(0xFFC06C4D);
    const background = Color(0xFFFDF8F5);
    const textDark = Color(0xFF1F2937);
    final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Consumer<LoanDetailsViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading && !viewModel.isInitialized) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDF8F5),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D))),
          );
        }

        final loan = viewModel.loan;
        if (loan == null && !viewModel.isLoading) {
          return Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(viewModel.errorMessage ?? 'Loan details could not be found.',
                      style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => viewModel.fetchLoanDetails(widget.loanId, forceRefresh: true),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryBrown),
                    child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          );
        } else if (loan == null) {
            return const Scaffold(
              backgroundColor: Color(0xFFFDF8F5),
              body: Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D))),
            );
        }

        final request = viewModel.request;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 80,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
              ),
              title: InkWell(
                onTap: () {
                  final verifiedShareholderId = loan.shareholderId.isNotEmpty ? loan.shareholderId : widget.shareholderId;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShareholderDetailPage(
                        shareholderId: verifiedShareholderId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE5E7EB),
                        child: Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(request?.shareholderName ?? 'Unknown Borrower',
                              style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Loan ID: ${loan.id}',
                              style: const TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
                  onPressed: () => viewModel.fetchLoanDetails(widget.loanId, forceRefresh: true),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _DetailsCard(loan: loan, request: request, currencyFormat: currencyFormat)),
                  const SizedBox(width: 32),
                  Expanded(flex: 1, child: _Sidebar(viewModel: viewModel, currencyFormat: currencyFormat, loan: loan, loanId: widget.loanId)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final LoanModel loan;
  final LoanRequestModel? request;
  final NumberFormat currencyFormat;

  const _DetailsCard({required this.loan, this.request, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    const primaryBrown = Color(0xFFC06C4D);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _InfoRow('Principal Amount', currencyFormat.format(loan.principalAmount)),
          _InfoRow('Interest Rate', '${(loan.interestRate * 100).toStringAsFixed(1)}%'),
          _InfoRow('Loan Tenure', '${loan.tenureMonths} Months'),
          _InfoRow('Total Repayable', currencyFormat.format(loan.totalRepayable)),
          _InfoRow('Disbursement Date', loan.releaseDate != null ? DateFormat('yyyy-MM-dd').format(loan.releaseDate!) : 'N/A'),
          if (loan.nextRepaymentDate != null)
            _InfoRow('Next Payment Due', DateFormat('yyyy-MM-dd').format(loan.nextRepaymentDate!), valueColor: primaryBrown),
          _InfoRow('Processing Fee', currencyFormat.format(loan.processingFee)),
          _InfoRow('Remaining Balance', currencyFormat.format(loan.remainingBalance), valueColor: Colors.red),
          const Divider(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Co-makers', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          if (request != null && request!.effectiveComakers.isNotEmpty)
            ...request!.effectiveComakers.map((cm) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cm.shareholderName, style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(
                    cm.status.name,
                    style: TextStyle(
                      color: cm.status == ComakerStatus.approved
                          ? Colors.green
                          : cm.status == ComakerStatus.rejected
                          ? Colors.red
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ))
          else
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('None', style: TextStyle(color: Color(0xFF6B7280))),
              ],
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        Text(value, style: TextStyle(color: valueColor ?? const Color(0xFF1F2937), fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    ),
  );
}

class _Sidebar extends StatelessWidget {
  final LoanDetailsViewModel viewModel;
  final NumberFormat currencyFormat;
  final LoanModel loan;
  final String loanId;

  const _Sidebar({required this.viewModel, required this.currencyFormat, required this.loan, required this.loanId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF32211A), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          _ActionButton(Icons.payment_rounded, 'Record payment', () async {
            final refreshed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => LoanPaymentPage(
                  loanId: loan.id,
                  initialRequest: viewModel.request,
                ),
              ),
            );

            if (refreshed == true && context.mounted) {
              await viewModel.fetchLoanDetails(loanId, forceRefresh: true);
            }
          }),
          _ActionButton(Icons.print, 'Print statement', () => viewModel.handleAction('Print')),
          _ActionButton(Icons.edit, 'Edit details', () => viewModel.handleAction('Edit')),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24)),
          const Text('Payment History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: viewModel.paymentHistory.isEmpty
                ? const Center(child: Text('No payments yet', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
              itemCount: viewModel.paymentHistory.length,
              itemBuilder: (context, index) {
                final item = viewModel.paymentHistory[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(item.date), style: const TextStyle(color: Colors.white70)),
                      Text(currencyFormat.format(item.amount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC06C4D), size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    ),
  );
}
