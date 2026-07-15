import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/views/loan_details_page.dart';

import 'package:capstone_application/viewmodels/navigation_viewmodel.dart';

class LoanApprovalPage extends StatefulWidget {
  final LoanRequestModel initialRequest;
  final VoidCallback? onBack;

  const LoanApprovalPage(
      {super.key, required this.initialRequest, this.onBack});

  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleDisbursement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lendingRepo = context.read<LendingRepository>();
      final loan = await lendingRepo.disburse(widget.initialRequest.id);

      if (loan != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan disbursed successfully')),
        );

        final nav = context.read<NavigationViewModel>();
        nav.navigateToLoanDetails(loan.id, loan.shareholderId);
      } else {
        setState(
            () => _errorMessage = 'Disbursement failed. Please try again.');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₱ ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: const Text('Confirm Disbursement',
            style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Approved Loan Summary',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF32211A))),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                      'Borrower', widget.initialRequest.shareholderName),
                  _buildDetailRow(
                      'Requested Amount',
                      currencyFormat
                          .format(widget.initialRequest.requestedAmount),
                      isBold: true),
                  _buildDetailRow(
                      'Tenure', '${widget.initialRequest.tenureMonths} Months'),
                  _buildDetailRow('Interest Rate',
                      '${(widget.initialRequest.interestRate * 100).toStringAsFixed(1)}%'),
                  const Divider(height: 32),
                  const Text(
                      'Final confirmation is required to release the funds to the shareholder.',
                      style:
                          TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            Semantics(
              label: 'Confirm and release funds',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleDisbursement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC06C4D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm & Release Funds',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
