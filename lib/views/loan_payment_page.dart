import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../viewmodels/loan_payment_viewmodel.dart';

class LoanPaymentPage extends StatefulWidget {
  final LoanRequestModel? initialRequest;
  final String? loanId;

  const LoanPaymentPage({super.key, this.initialRequest, this.loanId});

  @override
  State<LoanPaymentPage> createState() => _LoanPaymentPageState();
}

class _LoanPaymentPageState extends State<LoanPaymentPage> {
  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG [LoanPaymentPage]: Building ChangeNotifierProvider. initialRequest ID: ${widget.initialRequest?.id}, loanId: ${widget.loanId}');
    return ChangeNotifierProvider(
      create: (context) => LoanPaymentViewModel(context.read<LendingRepository>()),
      child: _LoanPaymentBody(
        initialRequest: widget.initialRequest,
        loanId: widget.loanId,
      ),
    );
  }
}

class _LoanPaymentBody extends StatefulWidget {
  final LoanRequestModel? initialRequest;
  final String? loanId;

  const _LoanPaymentBody({required this.initialRequest, required this.loanId});

  @override
  State<_LoanPaymentBody> createState() => _LoanPaymentBodyState();
}

class _LoanPaymentBodyState extends State<_LoanPaymentBody> {
  final _amountController = TextEditingController();
  String _method = LoanPaymentViewModel.paymentMethods.first;
  bool _amountInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('DEBUG [LoanPaymentPage]: Post-frame initialization callback. Triggering viewmodel load...');
      context.read<LoanPaymentViewModel>().load(
        initialRequest: widget.initialRequest,
        loanId: widget.loanId,
      );
    });
  }

  @override
  void dispose() {
    debugPrint('DEBUG [LoanPaymentPage]: Disposing controllers.');
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount() {
    final raw = _amountController.text.replaceAll(',', '').replaceAll('₱', '').trim();
    final parsed = double.tryParse(raw);
    debugPrint('DEBUG [LoanPaymentPage]: Parsing payment text input raw: "$raw" -> parsed: $parsed');
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Consumer<LoanPaymentViewModel>(
      builder: (context, viewModel, _) {
        final loan = viewModel.loan;
        final req = viewModel.request;

        debugPrint('DEBUG [LoanPaymentPage] State Consumer Update: isLoading=${viewModel.isLoading}, loanExists=${loan != null}, error=${viewModel.errorMessage}');

        if (!viewModel.isLoading && loan != null && !_amountInitialized) {
          _amountInitialized = true;
          final s = viewModel.suggestedAmount;
          _amountController.text = s > 0 ? s.toStringAsFixed(2) : '';
          debugPrint('DEBUG [LoanPaymentPage]: Suggested payment text input initialized with value: ${_amountController.text}');
        }

        if (viewModel.isLoading && loan == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFFDF8F5),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC06C4D))),
          );
        }

        if (loan == null) {
          debugPrint('DEBUG [LoanPaymentPage]: Rendering fallback blank/error screen because loan instance is null.');
          return Scaffold(
            backgroundColor: const Color(0xFFFDF8F5),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textDark),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Record payment', style: TextStyle(color: AppTheme.textDark, fontSize: 16)),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  viewModel.errorMessage ?? 'Unable to load loan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ),
            ),
          );
        }

        final borrowerName = req?.shareholderName ?? 'Borrower';
        final interestPortion = (loan.totalRepayable - loan.principalAmount).clamp(0.0, double.infinity);
        final totalDue = loan.remainingBalance;

        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF32211A)),
              onPressed: () {
                debugPrint('DEBUG [LoanPaymentPage]: User tapped upper Close button.');
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'Record Loan Payment',
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
                      // Left Column: Entry Form & Balance Details Card
                      Expanded(
                        flex: 2,
                        child: _buildPaymentFormCard(viewModel, currencyFormat, loan, borrowerName),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Summary Breakdowns & Metrics
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildRightSidebarSummary(currencyFormat, loan, interestPortion, totalDue),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (viewModel.errorMessage != null) ...[
                    Text(viewModel.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                    const SizedBox(height: 16),
                  ],
                  _buildActionButtons(context, viewModel),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentFormCard(
      LoanPaymentViewModel viewModel,
      NumberFormat currencyFormat,
      LoanModel loan,
      String borrowerName,
      ) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Processing Profile: $borrowerName',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC06C4D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ID: ${loan.id}',
                  style: const TextStyle(color: Color(0xFFC06C4D), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel('Payment amount'),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: 'Enter amount',
              filled: true,
              fillColor: const Color(0xFFFDFDFD),
              prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.textMuted, size: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFC06C4D)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suggested: ${currencyFormat.format(viewModel.suggestedAmount)} · Max: ${currencyFormat.format(loan.remainingBalance)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          _buildLabel('Payment method'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _method,
                isExpanded: true,
                items: LoanPaymentViewModel.paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  debugPrint('DEBUG [LoanPaymentPage]: Payment method selection changed from $_method to $v');
                  setState(() => _method = v ?? _method);
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          _buildFundInfo(currencyFormat, loan),
        ],
      ),
    );
  }

  Widget _buildRightSidebarSummary(
      NumberFormat currencyFormat,
      LoanModel loan,
      double interestPortion,
      double totalDue,
      ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF32211A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ledger Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          _buildMetricRow('Principal', currencyFormat.format(loan.principalAmount), labelColor: Colors.white70, valueColor: Colors.white),
          const Divider(height: 24, color: Colors.white24),
          _buildMetricRow('Interest Portion', currencyFormat.format(interestPortion < 0 ? 0 : interestPortion), labelColor: Colors.white70, valueColor: Colors.white),
          const Divider(height: 24, color: Colors.white24),
          _buildMetricRow('Total Repayable', currencyFormat.format(loan.totalRepayable), labelColor: Colors.white70, valueColor: Colors.white),
          const Divider(height: 24, color: Colors.white24),
          _buildMetricRow('Outstanding Balance', currencyFormat.format(totalDue), labelColor: Colors.white54, valueColor: const Color(0xFFC06C4D), isBold: true),
        ],
      ),
    );
  }

  Widget _buildFundInfo(NumberFormat currencyFormat, LoanModel loan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amortization Target Parameters',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
          ),
          const SizedBox(height: 12),
          _buildMetricRow('Current Outstanding', currencyFormat.format(loan.remainingBalance)),
          const SizedBox(height: 8),
          _buildMetricRow('Target Monthly Installment', currencyFormat.format(loan.monthlyAmortization), valueColor: const Color(0xFFC06C4D)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LoanPaymentViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 150,
          child: OutlinedButton(
            onPressed: viewModel.isSubmitting ? null : () {
              debugPrint('DEBUG [LoanPaymentPage]: Cancel execution triggered via button interaction.');
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textDark,
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 220,
          child: ElevatedButton(
            onPressed: viewModel.isSubmitting || viewModel.loan == null
                ? null
                : () async {
              debugPrint('DEBUG [LoanPaymentPage]: "Confirm Payment" button pressed.');
              final amt = _parseAmount();
              if (amt == null || amt <= 0) {
                debugPrint('DEBUG [LoanPaymentPage]: Validation failed. Amount is invalid or less than zero ($amt). Showing snackbar.');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid payment amount')),
                );
                return;
              }

              debugPrint('DEBUG [LoanPaymentPage]: Forwarding payload parameters to submitPayment... Amount: $amt, Method: $_method');
              final ok = await viewModel.submitPayment(amount: amt, method: _method);

              if (!context.mounted) {
                debugPrint('DEBUG [LoanPaymentPage]: Context unmounted after async submission. Aborting navigation sequence.');
                return;
              }

              debugPrint('DEBUG [LoanPaymentPage]: Submission completed. Operational response code: $ok');
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment recorded successfully')),
                );
                Navigator.pop(context, true);
              } else {
                debugPrint('DEBUG [LoanPaymentPage]: Error detected inside repository sequence: ${viewModel.errorMessage}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(viewModel.errorMessage ?? 'Payment failed')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC06C4D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: viewModel.isSubmitting
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isBold = false, Color? labelColor, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: labelColor ?? AppTheme.textMuted)),
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