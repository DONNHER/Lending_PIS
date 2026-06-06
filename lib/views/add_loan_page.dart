import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';
import '../viewmodels/add_loan_viewmodel.dart';
import '../widgets/shareholder_search_overlay.dart';

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
  final currencyFormat = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddLoanViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Loan Request',
            style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        centerTitle: true,
        // Using minHeight instead of height for the LinearProgressIndicator
        bottom: viewModel.isLoading 
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2, color: Color(0xFFC06C4D), backgroundColor: Colors.transparent),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provide loan details',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 24),

                    // Step 1: Select Borrower
                    _buildStepLabel('Step 1'),
                    const Text('Select Borrower',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    ShareholderSearchOverlay(
                      hint: 'Search borrower...',
                      results: viewModel.borrowerSearchResults,
                      onSearch: viewModel.setBorrowerSearchQuery,
                      navigateToDetail: false,
                      onSelected: (s) => viewModel.setBorrower(s),
                      selectedItem: viewModel.selectedBorrower != null
                          ? Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Chip(
                          label: Text(viewModel.selectedBorrower!.fullName),
                          onDeleted: () => viewModel.setBorrower(null),
                          backgroundColor: const Color(0xFFF2E4D8),
                          deleteIconColor: const Color(0xFFC06C4D),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                          : null,
                    ),
                      
                    const SizedBox(height: 24),

                    // Step 2: Amount
                    _buildStepLabel('Step 2'),
                    const Text('Loan amount (Max ₱10,000.00)',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        '₱${currencyFormat.format(viewModel.amount)}',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF32211A)),
                      ),
                    ),
                    Slider(
                      value: viewModel.amount,
                      min: 500,
                      max: 10000,
                      divisions: 19,
                      activeColor: const Color(0xFFC06C4D),
                      inactiveColor: const Color(0xFFE5E7EB),
                      onChanged: viewModel.setAmount,
                    ),
                    const SizedBox(height: 24),

                    // Step 3: Plan
                    _buildStepLabel('Step 3'),
                    const Text('Select duration',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    _buildDurationSelector(viewModel),
                    const SizedBox(height: 16),
                    _buildPlanSummaryCard(viewModel),
                    const SizedBox(height: 24),

                    // Step 4: Purpose
                    _buildStepLabel('Step 4'),
                    const Text('Loan purpose',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
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
                    const Text('Select 2 Co-makers',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    ShareholderSearchOverlay(
                      hint: 'Search co-maker...',
                      results: viewModel.coMakerSearchResults,
                      onSearch: viewModel.setCoMakerSearchQuery,
                      navigateToDetail: false,
                      onSelected: (s) {
                        if (s != null) viewModel.toggleCoMaker(s);
                      },
                      selectedItem: viewModel.selectedCoMakers.isNotEmpty
                          ? Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Wrap(
                          spacing: 8,
                          children: viewModel.selectedCoMakers
                              .map((cm) => Chip(
                            label: Text(cm.fullName,
                                style: const TextStyle(fontSize: 11)),
                            onDeleted: () => viewModel.toggleCoMaker(cm),
                            backgroundColor: const Color(0xFFF2E4D8),
                            deleteIconColor: const Color(0xFFC06C4D),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ))
                              .toList(),
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 24),

                    _buildSummarySection(viewModel),
                  ],
                ),
              ),
            ),

            // Fixed Footer
            _buildFixedFooter(context, viewModel),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSummarySection(AddLoanViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _summaryRow('Base Loan', 'PHP ${currencyFormat.format(viewModel.amount)}'),
          _summaryRow('Total Interest (${viewModel.months} mo)',
              'PHP ${currencyFormat.format(viewModel.totalInterest)}'),
          _summaryRow('5% Processing Fee',
              '-${currencyFormat.format(viewModel.processingFee)}'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total to Receive',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              Text('₱ ${currencyFormat.format(viewModel.netAmountToReceive)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF32211A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFixedFooter(BuildContext context, AddLoanViewModel viewModel) {
    final bool hasBorrower = viewModel.selectedBorrower != null;
    final bool hasCoMakers = viewModel.selectedCoMakers.length >= 2;
    final bool canSubmit = hasBorrower && hasCoMakers;

    String buttonText = 'Submit Loan Request';
    if (!hasBorrower) {
      buttonText = 'Select Borrower';
    } else if (!hasCoMakers) {
      buttonText = 'Select 2 Co-makers';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: (viewModel.isLoading || !canSubmit)
            ? null
            : () async {
          final success = await viewModel.submitLoanRequest();
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loan request submitted successfully')));
            Navigator.pop(context);
          } else if (viewModel.errorMessage != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(viewModel.errorMessage!),
                backgroundColor: AppTheme.error));
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
            ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildDurationSelector(AddLoanViewModel viewModel) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: viewModel.durationOptions.map((months) {
        final isSelected = viewModel.months == months;
        String label = months < 12 ? '$months Mo' : '1 Year';
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) { if (selected) viewModel.setMonths(months); },
          selectedColor: const Color(0xFFC06C4D),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF32211A),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? const Color(0xFFC06C4D) : const Color(0xFFE5E7EB)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlanSummaryCard(AddLoanViewModel viewModel) {
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${viewModel.months} ${viewModel.months == 1 ? 'Month' : 'Months'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('${(viewModel.interestRate * 100).toStringAsFixed(1)}% monthly interest',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₱ ${currencyFormat.format(viewModel.monthlyAmortization)}/mo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFC06C4D))),
            const Text('Amortization', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ]),
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
}
