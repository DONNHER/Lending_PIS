import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/transaction_repository.dart';
import '../viewmodels/add_share_capital_viewmodel.dart';
import '../models/shareholder_model.dart';
import 'ShareHolder_screens/details_page/repayment_details.dart';

class AddShareCapitalPage extends StatelessWidget {
  final ShareholderModel shareholder;

  const AddShareCapitalPage({super.key, required this.shareholder});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddShareCapitalViewModel(
        shareholderRepo: context.read<ShareholderRepository>(),
        transactionRepo: context.read<TransactionRepository>(),
        shareholder: shareholder,
      ),
      child: const _AddShareCapitalBody(),
    );
  }
}

class _AddShareCapitalBody extends StatelessWidget {
  const _AddShareCapitalBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddShareCapitalViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Share Capital',
          style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side: Share Capital Form Card
                  Expanded(
                    flex: 2,
                    child: _buildFormCard(context, viewModel),
                  ),
                  const SizedBox(width: 24),
                  // Right Side: Share Capital & Investment Portfolio Details Card
                  Expanded(
                    flex: 1,
                    child: _buildSummaryCard(viewModel, currencyFormat),
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
  }

  Widget _buildFormCard(BuildContext context, AddShareCapitalViewModel viewModel) {
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
          _buildFieldLabel('Shareholder Account Owner'),
          TextField(
            readOnly: true,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            decoration: _inputDecoration(
              hint: viewModel.shareholder.fullName,
              fillColor: const Color(0xFFF9FAFB),
              suffixIcon: Icons.verified_user_outlined,
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Capital Addition Amount'),
          TextField(
            controller: viewModel.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => viewModel.updateUI(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            decoration: _inputDecoration(hint: '5,000.00', prefix: '₱ '),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Payment Method'),
          TextField(
            readOnly: true,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration(
              hint: viewModel.selectedPaymentMethod,
              suffixIcon: Icons.open_in_new_outlined,
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Target Ledger Asset Block'),
          TextField(
            readOnly: true,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Core Common Share Capital Vault',
              fillColor: const Color(0xFFFDF8F5),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF2E4D8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Processing Capital Investment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current registered capital holding: ${NumberFormat.currency(symbol: '₱ ', decimalDigits: 2).format(viewModel.shareholder.totalShareCapital)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Note: Additions will be verified against system ledgers and compounded directly into the asset portfolio metrics.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AddShareCapitalViewModel viewModel, NumberFormat currencyFormat) {
    final double addedAmount = double.tryParse(viewModel.amountController.text) ?? 0.0;
    final double updatedTotalCapital = viewModel.shareholder.totalShareCapital + addedAmount;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF32211A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio Summary',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 32),
          _summaryItem('Account Holder', viewModel.shareholder.fullName),
          _summaryItem('Current Share Capital', currencyFormat.format(viewModel.shareholder.totalShareCapital)),
          _summaryItem('Pending Deposit Addition', currencyFormat.format(addedAmount)),
          _summaryItem('Credit Rating Tier', '${viewModel.shareholder.creditScore} Index'),
          const Divider(color: Colors.white24, height: 32),
          const Text('Projected Total Capital', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(updatedTotalCapital),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AddShareCapitalViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 150,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textDark,
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 240,
          child: ElevatedButton(
            onPressed: viewModel.isLoading
                ? null
                : () async {
              final transaction = await viewModel.executeInvestment();
              if (transaction != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Capital deposit executed successfully')),
                );
                
                // 🚀 Redirect to the Transaction Detail (Receipt) page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RepaymentDetailsScreen(transaction: transaction),
                  ),
                ).then((_) {
                  // After they close the receipt, return 'true' to the profile page to refresh
                  if (context.mounted) Navigator.pop(context, true);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC06C4D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: viewModel.isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : const Text('Confirm Capital Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, String? prefix, IconData? suffixIcon, Color? fillColor}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20, color: AppTheme.textMuted) : null,
      filled: true,
      fillColor: fillColor ?? Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }
}