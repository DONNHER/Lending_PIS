import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/interest_rate_history_model.dart';
import '../repositories/lending_repository.dart';
import '../viewmodels/update_interest_viewmodel.dart';

class UpdateInterestPage extends StatelessWidget {
  const UpdateInterestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UpdateInterestViewModel(context.read<LendingRepository>()),
      child: const _UpdateInterestBody(),
    );
  }
}

class _UpdateInterestBody extends StatefulWidget {
  const _UpdateInterestBody();

  @override
  State<_UpdateInterestBody> createState() => _UpdateInterestBodyState();
}

class _UpdateInterestBodyState extends State<_UpdateInterestBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdateInterestViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateInterestViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF8F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Text(
              'Interest Rate Settings', 
              style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
                onPressed: () => viewModel.loadData(forceRefresh: true),
                tooltip: 'Refresh Data',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => viewModel.loadData(forceRefresh: true),
              color: const Color(0xFFC06C4D),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Current Rate & Form
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildCurrentRateCard(viewModel),
                          const SizedBox(height: 24),
                          _buildUpdateForm(context, viewModel),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Side: Audit Log
                    Expanded(
                      flex: 1,
                      child: _buildAuditLogCard(viewModel),
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

  Widget _buildCurrentRateCard(UpdateInterestViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E4D8), // Light peach background from image
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Interest Rate',
            style: TextStyle(
              color: Color(0xFFC06C4D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(viewModel.currentRate * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Color(0xFFC06C4D),
              fontSize: 48,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Applied to ${viewModel.activeLoansCount} active loans',
            style: TextStyle(
              color: const Color(0xFFC06C4D).withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateForm(BuildContext context, UpdateInterestViewModel viewModel) {
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
            'Update Form',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('New Rate (%) *'),
          TextField(
            controller: viewModel.rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(hint: '3.5', suffix: '%'),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Effective Date *'),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) viewModel.setEffectiveDate(date);
            },
            child: IgnorePointer(
              child: TextField(
                decoration: _inputDecoration(
                  hint: viewModel.selectedEffectiveDate != null 
                    ? DateFormat('MMMM dd, yyyy').format(viewModel.selectedEffectiveDate!) 
                    : 'Select Date',
                  suffixIcon: Icons.calendar_today_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('Change Reason *'),
          TextField(
            controller: viewModel.reasonController,
            maxLines: 4,
            decoration: _inputDecoration(hint: 'Explain why this rate is being updated...'),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading 
                    ? null 
                    : () async {
                        final success = await viewModel.applyChanges();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Interest rate updated successfully')),
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
                  child: viewModel.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: viewModel.clearForm,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Clear', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(viewModel.errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(UpdateInterestViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audit Log - Rate History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Historical record of all rate changes (immutable)',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            color: const Color(0xFF32211A), // Dark brown header from image
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Rate Change', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 4, child: Text('Reason', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
               ],
            ),
          ),
          // Table Rows
          ...viewModel.history.map((entry) => _buildHistoryRow(entry)),
          if (viewModel.history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No history found', style: TextStyle(color: AppTheme.textMuted))),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(InterestRateHistoryModel entry) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(dateFormat.format(entry.createdAt), style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text('${(entry.oldRate * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const Icon(Icons.arrow_right_alt, size: 16, color: Color(0xFFC06C4D)),
                  Text('${(entry.newRate * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC06C4D))),
                ],
              )
          ),

          // ✨ REASON COLUMN: Truncated text with elegant hover-to-reveal tooltips
          Expanded(
            flex: 4,
            child: Tooltip(
              message: entry.reason, // Displays the entire multi-line block text on hover or press
              preferBelow: false,
              child: Text(
                entry.reason.trim(),
                maxLines: 1, // Restricts row heights from exploding on lengthy explanations
                overflow: TextOverflow.ellipsis, // Cleanly forces trailing '...' string truncation
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
    );
  }

  InputDecoration _inputDecoration({required String hint, String? suffix, IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixText: suffix,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20, color: AppTheme.textMuted) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }
}
