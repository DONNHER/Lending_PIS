import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../viewmodels/loan_approval_viewmodel.dart';

class LoanApprovalPage extends StatelessWidget {
  final LoanRequestModel? initialRequest;

  const LoanApprovalPage({super.key, this.initialRequest});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoanApprovalViewModel(
        context.read<LendingRepository>(),
        initialRequest: initialRequest,
      ),
      child: const _LoanApprovalBody(),
    );
  }
}

class _LoanApprovalBody extends StatelessWidget {
  const _LoanApprovalBody();

  void _showProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFC06C4D)),
              SizedBox(height: 16),
              Text("Releasing Disbursement...", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Updating ledger and generating loan records.", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Consumer<LoanApprovalViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading && viewModel.selectedLoan == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D))),
          );
        }

        final loan = viewModel.selectedLoan;

        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Loan Disbursement', style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 800;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildLeftColumn(viewModel, currencyFormat)),
                            const SizedBox(width: 24),
                            Expanded(flex: 1, child: _buildRightColumn(viewModel, currencyFormat)),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildLeftColumn(viewModel, currencyFormat),
                            const SizedBox(height: 24),
                            _buildRightColumn(viewModel, currencyFormat),
                          ],
                        ),
                      const SizedBox(height: 32),
                      _buildActionButtons(context, viewModel, isWide),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn(LoanApprovalViewModel viewModel, NumberFormat currencyFormat) {
    return Column(
      children: [
        _buildApprovedSummary(viewModel, currencyFormat),
        const SizedBox(height: 24),
        _buildDisbursementForm(viewModel, currencyFormat),
      ],
    );
  }

  Widget _buildRightColumn(LoanApprovalViewModel viewModel, NumberFormat currencyFormat) {
    return Column(
      children: [
        _buildRepaymentSchedule(viewModel, currencyFormat),
        const SizedBox(height: 24),
        _buildFundingStatus(viewModel),
      ],
    );
  }

  Widget _buildApprovedSummary(LoanApprovalViewModel viewModel, NumberFormat currencyFormat) {
    final loan = viewModel.selectedLoan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approved Loan Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 40,
            runSpacing: 20,
            children: [
              _buildInfoItem('Loan ID', loan?.id.split('-').first ?? 'N/A', isBold: true),
              _buildInfoItem('Principal Amount', currencyFormat.format(loan?.requestedAmount ?? 0), isBold: true),
              _buildInfoItem('Tenure', '${loan?.tenureMonths ?? 0} months'),
              _buildInfoItem('Interest Rate', '${((loan?.interestRate ?? 0) * 100).toStringAsFixed(1)}% per annum'),
              _buildInfoItem('Status', loan?.status.name.toUpperCase() ?? 'N/A', valueColor: const Color(0xFFC06C4D)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisbursementForm(LoanApprovalViewModel viewModel, NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disbursement Configuration',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
          ),
          const SizedBox(height: 24),
          if (viewModel.initialRequest == null) ...[
            const Text('Select Approved Loan', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: viewModel.selectedLoan?.id,
                  isExpanded: true,
                  hint: const Text('Select a loan'),
                  items: viewModel.approvedLoans.map((loan) {
                    return DropdownMenuItem(
                      value: loan.id,
                      child: Text('${loan.id.split('-').first} — ${loan.shareholderName}'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) viewModel.selectLoan(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          _buildInfoItem('Disbursement Method', 'Cash', isBold: true),
          const SizedBox(height: 20),
          _buildInfoItem('Net Amount to Release', currencyFormat.format(viewModel.selectedLoan?.requestedAmount ?? 0), isBold: true, valueColor: Colors.green),
        ],
      ),
    );
  }

  Widget _buildRepaymentSchedule(LoanApprovalViewModel viewModel, NumberFormat currencyFormat) {
    final loan = viewModel.selectedLoan;
    double principal = loan?.requestedAmount ?? 0;
    double interestRate = loan?.interestRate ?? 0;
    int tenure = loan?.tenureMonths ?? 0;
    
    double totalInterest = principal * interestRate * tenure;
    double totalRepayable = principal + totalInterest;
    double monthly = tenure > 0 ? totalRepayable / tenure : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repayment Schedule',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
          ),
          const SizedBox(height: 20),
          _buildMetricRow('Monthly Amortization', currencyFormat.format(monthly), valueColor: const Color(0xFFC06C4D), isBold: true),
          const Divider(height: 24),
          _buildMetricRow('Total Interest', currencyFormat.format(totalInterest)),
          const Divider(height: 24),
          _buildMetricRow('Processing Fee (5%)', currencyFormat.format(principal * 0.05)),
          const Divider(height: 24),
          _buildMetricRow('Total Repayable', currencyFormat.format(totalRepayable), isBold: true),
        ],
      ),
    );
  }

  Widget _buildFundingStatus(LoanApprovalViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E4D8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC06C4D).withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Funding Status',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
          ),
          SizedBox(height: 12),
          Text('Available Pool:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Text('₱ 240,000.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC06C4D))),
          SizedBox(height: 8),
          Text('Status: Sufficient Funds', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LoanApprovalViewModel viewModel, bool isWide) {
    final buttons = [
      SizedBox(
        width: isWide ? 150 : double.infinity,
        child: OutlinedButton(
          onPressed: viewModel.isProcessingAction ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textDark,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      if (isWide) const SizedBox(width: 16) else const SizedBox(height: 12),
      SizedBox(
        width: isWide ? 250 : double.infinity,
        child: ElevatedButton(
          onPressed: viewModel.selectedLoan == null ||
                  viewModel.isLoading ||
                  viewModel.isProcessingAction ||
                  viewModel.selectedLoan!.status != LoanStatus.approved
              ? null
              : () async {
                  _showProcessingDialog(context);
                  final success = await viewModel.releaseDisbursement();
                  if (context.mounted) Navigator.pop(context); // Close dialog

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Disbursement released successfully')),
                      );
                      Navigator.pop(context, true);
                    } else {
                      final message = viewModel.errorMessage ?? 'Could not release disbursement';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC06C4D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: viewModel.isProcessingAction
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Release Disbursement', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ];

    return isWide 
        ? Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons)
        : Column(children: buttons);
  }

  Widget _buildInfoItem(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
