import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../viewmodels/loan_evaluation_viewmodel.dart';
import 'loan_approval_page.dart';

class LoanEvaluationPage extends StatelessWidget {
  final LoanRequestModel request;

  const LoanEvaluationPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoanEvaluationViewModel(
        context.read<LendingRepository>(),
        context.read<ShareholderRepository>(),
        request,
      ),
      child: const _LoanEvaluationBody(),
    );
  }
}

class _LoanEvaluationBody extends StatelessWidget {
  const _LoanEvaluationBody();

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
              Text("Processing Loan Request...", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Please wait while we update the records.", style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Consumer<LoanEvaluationViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Loan Evaluation', style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildProfileSnapshot(viewModel, currencyFormat),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildRiskAssessment(viewModel),
                            const SizedBox(height: 24),
                            _buildEvaluationMetrics(viewModel, currencyFormat),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(context, viewModel),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, LoanEvaluationViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 150,
          child: OutlinedButton(
            onPressed: viewModel.isLoading ? null : () => _handleStatusUpdate(context, viewModel, LoanStatus.rejected),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 220,
          child: ElevatedButton(
            onPressed: viewModel.isLoading ? null : () => _handleStatusUpdate(context, viewModel, LoanStatus.approved),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC06C4D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Approve & Process', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleStatusUpdate(BuildContext context, LoanEvaluationViewModel viewModel, LoanStatus status) async {
    final allComakersApproved = viewModel.request.effectiveComakers.every(
            (cm) => cm.status == ComakerStatus.approved
    );

    if (status == LoanStatus.approved && !allComakersApproved) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approval Restricted'),
          content: const Text('This loan cannot be approved yet. All listed co-makers must approve the request before the final processing.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Understood', style: TextStyle(color: Color(0xFFC06C4D))),
            ),
          ],
        ),
      );
      return;
    }

    _showProcessingDialog(context);

    try {
      final success = await viewModel.updateStatus(status);
      
      if (context.mounted) Navigator.pop(context); // Close loading dialog

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan request ${status.name} successfully')),
        );

        if (status == LoanStatus.approved) {
          final updatedRequest = viewModel.request.copyWith(status: LoanStatus.approved);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoanApprovalPage(initialRequest: updatedRequest),
            ),
          );
        } else {
          Navigator.pop(context);
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage ?? 'Update failed')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      debugPrint('CRITICAL EXCEPTION during status update: $e');
    }
  }

  Widget _buildProfileSnapshot(LoanEvaluationViewModel viewModel, NumberFormat currencyFormat) {
    return Container(
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
            'Loan Application Profile & Evaluation Snapshot',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Requested Amount', currencyFormat.format(viewModel.request.requestedAmount), isBold: true),
                    const SizedBox(height: 20),
                    _buildInfoItem('Tenure', '${viewModel.request.tenureMonths} months'),
                    const SizedBox(height: 20),
                    _buildInfoItem('Purpose', viewModel.request.purpose),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('Interest Rate', '${(viewModel.request.interestRate * 100).toStringAsFixed(0)}% per annum'),
                    const SizedBox(height: 20),
                    _buildInfoItem(
                      'Credit Score',
                      '${viewModel.shareholder?.creditScore ?? 0} (Good)',
                      valueColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          _buildComakersSection(viewModel),
        ],
      ),
    );
  }

  Widget _buildComakersSection(LoanEvaluationViewModel viewModel) {
    final rows = viewModel.request.effectiveComakers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Co-maker Responses',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Approval logic requires status confirmation from all parties.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const Text('No co-makers required for this loan.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
        ...rows.map((cm) {
          final name = viewModel.comakerName(cm.shareholderId);
          final label = switch (cm.status) {
            ComakerStatus.approved => 'Approved',
            ComakerStatus.rejected => 'Rejected',
            ComakerStatus.pending => 'Pending',
          };
          final color = switch (cm.status) {
            ComakerStatus.approved => Colors.green,
            ComakerStatus.rejected => Colors.red,
            ComakerStatus.pending => Colors.orange,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRiskAssessment(LoanEvaluationViewModel viewModel) {
    return Container(
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
            'Risk Assessment & Recommendation',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
          ),
          const SizedBox(height: 20),
          const Text('Risk Level', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: viewModel.riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              viewModel.riskLevel,
              style: TextStyle(color: viewModel.riskColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoItem('Recommendation', viewModel.recommendation, isBold: true),
          const SizedBox(height: 20),
          _buildInfoItem('Priority', 'Normal'),
        ],
      ),
    );
  }

  Widget _buildEvaluationMetrics(LoanEvaluationViewModel viewModel, NumberFormat currencyFormat) {
    return Container(
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
            'Evaluation Metrics',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
          ),
          const SizedBox(height: 20),
          _buildMetricRow('Repayment Capacity', '${(viewModel.repaymentCapacity * 100).toInt()}%', valueColor: Colors.green),
          const Divider(height: 24),
          _buildMetricRow('Debt-to-Income', '${(viewModel.debtToIncome * 100).toInt()}%'),
          const Divider(height: 24),
          _buildMetricRow('Collateral Value', currencyFormat.format(0)),
          const Divider(height: 24),
          _buildMetricRow('Final Score', '${viewModel.finalScore.toStringAsFixed(0)}/10', isBold: true, valueColor: const Color(0xFFC06C4D)),
        ],
      ),
    );
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
