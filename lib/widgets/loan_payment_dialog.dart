import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../viewmodels/loan_payment_viewmodel.dart';
import 'transaction_detail_dialog.dart';

class LoanPaymentDialog extends StatefulWidget {
  final LoanRequestModel? initialRequest;
  final String? loanId;

  const LoanPaymentDialog({super.key, this.initialRequest, this.loanId});

  @override
  State<LoanPaymentDialog> createState() => _LoanPaymentDialogState();
}

class _LoanPaymentDialogState extends State<LoanPaymentDialog> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoanPaymentViewModel(context.read<LendingRepository>()),
      child: _LoanPaymentDialogBody(
        initialRequest: widget.initialRequest,
        loanId: widget.loanId,
      ),
    );
  }
}

class _LoanPaymentDialogBody extends StatefulWidget {
  final LoanRequestModel? initialRequest;
  final String? loanId;

  const _LoanPaymentDialogBody({required this.initialRequest, required this.loanId});

  @override
  State<_LoanPaymentDialogBody> createState() => _LoanPaymentDialogBodyState();
}

class _LoanPaymentDialogBodyState extends State<_LoanPaymentDialogBody> {
  final _amountController = TextEditingController();
  String _method = LoanPaymentViewModel.paymentMethods.first;
  bool _amountInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanPaymentViewModel>().load(
        initialRequest: widget.initialRequest,
        loanId: widget.loanId,
      );
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount() {
    final raw = _amountController.text.replaceAll(',', '').replaceAll('₱', '').trim();
    return double.tryParse(raw);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Consumer<LoanPaymentViewModel>(
      builder: (context, viewModel, _) {
        final loan = viewModel.loan;
        final req = viewModel.request;

        if (!viewModel.isLoading && loan != null && !_amountInitialized) {
          _amountInitialized = true;
          final s = viewModel.suggestedAmount;
          _amountController.text = s > 0 ? s.toStringAsFixed(2) : '';
        }

        if (viewModel.isLoading && loan == null) {
          return const Dialog(child: SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D)))));
        }

        if (loan == null) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(viewModel.errorMessage ?? 'Unable to load loan details.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          );
        }

        final borrowerName = req?.shareholderName ?? 'Borrower';
        final interestPortion = (loan.totalRepayable - loan.principalAmount).clamp(0.0, double.infinity);
        final totalDue = loan.remainingBalance;

        return Dialog(
          backgroundColor: const Color(0xFFFDF8F5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Record Loan Payment', style: TextStyle(color: Color(0xFFC06C4D), fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(borrowerName, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 2, child: _buildPaymentHistoryCard(viewModel, currencyFormat)),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildPaymentFormCard(viewModel, currencyFormat, loan, borrowerName)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildCombinedSummary(currencyFormat, loan, interestPortion, totalDue),
                  const SizedBox(height: 32),
                  if (viewModel.errorMessage != null) ...[
                    Text(viewModel.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                    const SizedBox(height: 16),
                  ],
                  _buildActionButtons(context, viewModel, currencyFormat, borrowerName),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentFormCard(LoanPaymentViewModel viewModel, NumberFormat currencyFormat, LoanModel loan, String borrowerName) {
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
          const Text('Payment Processing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF32211A))),
          const SizedBox(height: 24),
          _buildLabel('Payment amount'),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              hintText: 'Enter amount',
              filled: true,
              fillColor: const Color(0xFFFDFDFD),
              prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.textMuted, size: 20),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC06C4D))),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suggested: ${currencyFormat.format(viewModel.suggestedAmount)} · Max: ${currencyFormat.format(loan.remainingBalance)}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          _buildLabel('Payment method'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _method,
                isExpanded: true,
                items: LoanPaymentViewModel.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _method = v ?? _method),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard(LoanPaymentViewModel viewModel, NumberFormat currencyFormat) {
    final history = viewModel.paymentHistory;
    final dateFormat = DateFormat('MMM dd, yyyy');

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
          const Text('Recent Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF32211A))),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Expanded(child: Center(child: Text('No payments recorded.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13))))
          else
            Expanded(
              child: ListView.separated(
                itemCount: history.length,
                separatorBuilder: (context, index) => const Divider(height: 20, color: Color(0xFFF3F4F6)),
                itemBuilder: (context, index) {
                  final tx = history[index];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFF80FF80).withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.payments_rounded, color: Colors.green, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateFormat.format(tx.date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text(tx.method, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          ],
                        ),
                      ),
                      Text(currencyFormat.format(tx.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCombinedSummary(NumberFormat currencyFormat, LoanModel loan, double interestPortion, double totalDue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF32211A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ledger & Amortization Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _summaryRow('Principal', currencyFormat.format(loan.principalAmount)),
                    const Divider(height: 16, color: Colors.white10),
                    _summaryRow('Interest', currencyFormat.format(interestPortion)),
                  ],
                ),
              ),
              const VerticalDivider(color: Colors.white10, width: 48),
              Expanded(
                child: Column(
                  children: [
                    _summaryRow('Outstanding', currencyFormat.format(totalDue), valueColor: const Color(0xFFC06C4D)),
                    const Divider(height: 16, color: Colors.white10),
                    _summaryRow('Monthly Target', currencyFormat.format(loan.monthlyAmortization), valueColor: const Color(0xFFC06C4D)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, LoanPaymentViewModel viewModel, NumberFormat currencyFormat, String borrowerName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: viewModel.isSubmitting ? null : () async {
            final amt = _parseAmount();
            if (amt == null || amt <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
              return;
            }

            final success = await viewModel.submitPayment(amount: amt, method: _method);
            if (success && context.mounted) {
              var tx = viewModel.lastTransaction!;
              if (tx.clientName == 'Unknown Client') tx = tx.copyWith(clientName: borrowerName);
              if (tx.amount <= 0) tx = tx.copyWith(amount: amt);
              if (tx.method == 'N/A') tx = tx.copyWith(method: _method);

              await showDialog(context: context, builder: (context) => TransactionDetailDialog(transaction: tx));
              if (context.mounted) Navigator.pop(context, true); // Return true to signal refresh
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC06C4D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: viewModel.isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark));
}
