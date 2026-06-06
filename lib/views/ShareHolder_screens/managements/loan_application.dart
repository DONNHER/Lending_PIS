import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/viewmodels/add_loan_viewmodel.dart';
import 'package:capstone_application/widgets/shareholder_search_selector.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class AddLoanPage extends StatelessWidget {
  const AddLoanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddLoanViewModel(
        context.read<LendingRepository>(),
        context.read<ShareholderRepository>(),
      ),
      child: const _AddLoanBody(),
    );
  }
}

class _AddLoanBody extends StatefulWidget {
  const _AddLoanBody();

  @override
  State<_AddLoanBody> createState() => _AddLoanBodyState();
}

class _AddLoanBodyState extends State<_AddLoanBody> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddLoanViewModel>();
    final currencyFormat = NumberFormat('#,##0.00');
    final isEligible = viewModel.isEligible;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Loan Request', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Eligibility Banner
            if (!isEligible && viewModel.eligibilityMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppTheme.error.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        viewModel.eligibilityMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Opacity(
                  opacity: isEligible ? 1.0 : 0.6,
                  child: AbsorbPointer(
                    absorbing: !isEligible,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Provide loan details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 24),

                        // Step 1: Borrower Information (Self-only for Shareholders)
                        _buildStepLabel('Step 1'),
                        const Text('Confirm Borrower', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 12),
                        ShareholderSearchSelector(
                          hint: 'Type your name to search...',
                          results: viewModel.borrowerSearchResults,
                          onSearch: viewModel.setBorrowerSearchQuery,
                          navigateToDetail: false,
                          initialValue: viewModel.selectedBorrower?.fullName,
                          onSelected: (s) {
                            viewModel.setBorrower(s);
                          },
                          selectedItem: null,
                        ),
                        const SizedBox(height: 24),

                        // Step 2: Amount
                        _buildStepLabel('Step 2'),
                        const Text('Loan amount (Max ₱10,000.00)', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            '₱${currencyFormat.format(viewModel.amount)}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF32211A)),
                          ),
                        ),
                        Slider(
                          value: viewModel.amount,
                          min: 500,
                          max: 10000,
                          divisions: 19,
                          activeColor: const Color(0xFFC06C4D),
                          onChanged: viewModel.setAmount,
                        ),
                        const SizedBox(height: 24),

                        // Step 3: Plan
                        _buildStepLabel('Step 3'),
                        const Text('Select duration', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 12),
                        _buildDurationSelector(viewModel),
                        const SizedBox(height: 16),
                        _buildPlanSummaryCard(viewModel, currencyFormat),
                        const SizedBox(height: 24),

                        // Step 4: Purpose
                        _buildStepLabel('Step 4'),
                        const Text('Loan purpose', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          value: viewModel.purpose,
                          items: ['Educational', 'Medical', 'Business', 'Emergency', 'Other'],
                          onChanged: (val) {
                            if (val != null) viewModel.setPurpose(val);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Step 5: Co-makers
                        _buildStepLabel('Step 5'),
                        const Text('Select 2 Co-makers', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        const SizedBox(height: 12),
                        ShareholderSearchSelector(
                          hint: 'Search co-maker...',
                          results: viewModel.coMakerSearchResults,
                          onSearch: viewModel.setCoMakerSearchQuery,
                          navigateToDetail: false,
                          onSelected: (s) {
                            if (s != null) {
                              viewModel.toggleCoMaker(s);
                            }
                          },
                          selectedItem: viewModel.selectedCoMakers.isNotEmpty
                              ? Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Wrap(
                              spacing: 8,
                              children: viewModel.selectedCoMakers.map((cm) => Chip(
                                label: Text(cm.fullName, style: const TextStyle(fontSize: 11)),
                                onDeleted: () => viewModel.toggleCoMaker(cm),
                                backgroundColor: const Color(0xFFF2E4D8),
                                deleteIconColor: const Color(0xFFC06C4D),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              )).toList(),
                            ),
                          )
                              : null,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildSummaryAndFooter(context, viewModel, currencyFormat, isEligible),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelector(AddLoanViewModel viewModel) {
    return Wrap(
      spacing: 12,
      children: viewModel.durationOptions.map((months) {
        final isSelected = viewModel.months == months;
        String label = months < 12 ? '$months Mo' : '1 Year';
        if (months == 1) label = '1 Mo';

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) viewModel.setMonths(months);
          },
          selectedColor: const Color(0xFFC06C4D),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF32211A),
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? const Color(0xFFC06C4D) : const Color(0xFFE5E7EB),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanSummaryCard(AddLoanViewModel viewModel, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC06C4D), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${viewModel.months} ${viewModel.months == 1 ? 'Month' : 'Months'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${(viewModel.interestRate * 100).toStringAsFixed(2)}% interest per mo', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱ ${format.format(viewModel.monthlyAmortization)}/mo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFC06C4D))),
              const Text('Repayment', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: const Color(0xFFF2E4D8), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Color(0xFFC06C4D), fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryAndFooter(BuildContext context, AddLoanViewModel viewModel, NumberFormat currencyFormat, bool isEligible) {
    final bool canSubmit = isEligible && viewModel.selectedBorrower != null && viewModel.selectedCoMakers.length >= 2;

    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _summaryRow('Base Loan', 'PHP ${currencyFormat.format(viewModel.amount)}'),
                _summaryRow('Total Interest (${viewModel.months} mo)', 'PHP ${currencyFormat.format(viewModel.totalInterest)}'),
                _summaryRow('5% Processing Fee', '-${currencyFormat.format(viewModel.processingFee)}'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total to Receive', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    Text('₱ ${currencyFormat.format(viewModel.netAmountToReceive)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF32211A))),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ElevatedButton(
              onPressed: (viewModel.isLoading || !canSubmit)
                  ? null
                  : () async {
                final success = await viewModel.submitLoanRequest();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loan request submitted successfully')));
                  Navigator.pop(context);
                } else if (viewModel.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.errorMessage!), backgroundColor: AppTheme.error));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC06C4D),
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: viewModel.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(!isEligible ? 'Ineligible for New Loan' : (!canSubmit ? 'Confirm Borrower & 2 Co-makers' : 'Submit Request'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
        ],
      ),
    );
  }
}
