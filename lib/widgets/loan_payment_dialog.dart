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

  // 🔒 Payment method is fixed to Cash only
  final String _method = 'Cash';

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
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: const SizedBox(
              height: 200,
              width: 400,
              child: Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D))),
            ),
          );
        }

        if (loan == null) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(viewModel.errorMessage ?? 'Unable to load loan details.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          );
        }

        final borrowerName = req?.shareholderName ?? 'Borrower';
        final shareholderId = req?.shareholderId ?? 'N/A';
        final totalDue = loan.remainingBalance;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header / Close button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                            splashRadius: 24,
                          ),
                        ],
                      ),
                    ),

                    // Payment Icon & Title
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC06C4D).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payments_rounded, size: 40, color: Color(0xFFC06C4D)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Record Loan Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF32211A),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Entry Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Payment amount'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            // 🔒 Allow digits with up to 2 decimal places only
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            decoration: InputDecoration(
                              hintText: '0.00',
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.textMuted, size: 20),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFC06C4D))),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Outstanding: ${currencyFormat.format(totalDue)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20),
                          _buildLabel('Payment method'),
                          const SizedBox(height: 8),
                          // 🔒 Fixed to Cash only — no dropdown, not editable
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.payments_outlined, size: 18, color: AppTheme.textMuted),
                                SizedBox(width: 10),
                                Text(
                                  'Cash',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                          const SizedBox(height: 24),
                          _detailRow('Borrower', borrowerName),
                          _detailRow('Shareholder ID', shareholderId),
                          _detailRow('Principal', currencyFormat.format(loan.principalAmount)),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: viewModel.isSubmitting ? null : () async {
                                final amt = _parseAmount();

                                if (amt == null || amt <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Enter a valid amount')),
                                  );
                                  return;
                                }

                                // 🔒 Payment cannot exceed the outstanding balance
                                if (amt > totalDue) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Amount cannot exceed the outstanding balance of ${currencyFormat.format(totalDue)}',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final success = await viewModel.submitPayment(amount: amt, method: _method);
                                if (success && context.mounted) {
                                  var tx = viewModel.lastTransaction!;
                                  if (tx.clientName == 'Unknown Client') tx = tx.copyWith(clientName: borrowerName);
                                  if (tx.amount <= 0) tx = tx.copyWith(amount: amt);
                                  if (tx.method == 'N/A') tx = tx.copyWith(method: _method);

                                  await showDialog(context: context, builder: (context) => TransactionDetailDialog(transaction: tx));

                                  // 🔒 Close only this dialog — do not pop the previous screen
                                  // or signal a reload via a return value.
                                  if (context.mounted) Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC06C4D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: viewModel.isSubmitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF32211A)));

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}