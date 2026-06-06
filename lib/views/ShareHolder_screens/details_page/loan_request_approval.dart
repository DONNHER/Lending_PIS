import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/models/shareholder_model.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/viewmodels/notification_viewmodel.dart';

class LoanRequestDetailsScreen extends StatefulWidget {
  final String loanRequestId;

  const LoanRequestDetailsScreen({super.key, required this.loanRequestId});

  @override
  State<LoanRequestDetailsScreen> createState() => _LoanRequestDetailsScreenState();
}

class _LoanRequestDetailsScreenState extends State<LoanRequestDetailsScreen> {
  // Design System Colors
  static const Color primaryGreen = Color(0xFF66FF66);
  static const Color accentRed = Color(0xFFFF4D4D);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color textGrey = Color(0xFF9CA3AF);

  final currencyFormat = NumberFormat.currency(symbol: '₱');

  Future<void> _submitDecision(ComakerStatus status) async {
    final lendingRepo = context.read<LendingRepository>();
    final shareholderId = context.read<NotificationViewModel>().shareholderId;

    if (shareholderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not found.')),
      );
      return;
    }

    try {
      await lendingRepo.setComakerDecision(
        loanRequestId: widget.loanRequestId,
        comakerShareholderId: shareholderId,
        status: status,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request ${status.name} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<Map<String, dynamic>> _fetchFullLoanData() async {
    final lendingRepo = context.read<LendingRepository>();
    final shareholderRepo = context.read<ShareholderRepository>();

    final loanRequest = await lendingRepo.getLoanRequestById(widget.loanRequestId);
    if (loanRequest == null) throw Exception("Loan request not found");

    final borrower = await shareholderRepo.getShareholderById(loanRequest.shareholderId);

    return {
      'loan': loanRequest,
      'borrower': borrower,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Request Review",
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchFullLoanData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final loan = snapshot.data!['loan'] as LoanRequestModel;
          final borrower = snapshot.data!['borrower'] as ShareholderModel?;

          // Corrected mapping based on your LoanRequestModel
          final double principal = loan.requestedAmount;
          final int duration = loan.tenureMonths;

          // Calculate interest amount: (Principal * Rate / 100)
          final double interestTotal = principal * (loan.interestRate / 100);

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildRequestHeader(principal),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Borrower Details"),
                      _buildProfileCard(
                          borrower?.fullName ?? loan.shareholderName, // Fallback to name in loan model
                          "ID: ${loan.shareholderId.substring(0, 8)}"
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle("Loan Summary"),
                      _buildInfoCard([
                        _buildDetailRow("Principal Amount", currencyFormat.format(principal)),
                        _buildDetailRow("Interest (${loan.interestRate}%)", currencyFormat.format(interestTotal)),
                        _buildDetailRow("Duration", "$duration Months"),
                        const Divider(height: 24),
                        _buildDetailRow("Total Repayable",
                            currencyFormat.format(principal + interestTotal), isBold: true),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle("Purpose"),
                      _buildInfoCard([
                        Text(loan.purpose, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                      ]),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomActionButtons(),
    );
  }

  Widget _buildRequestHeader(double amount) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text("Requested Amount", style: TextStyle(color: textGrey, fontSize: 14)),
          const SizedBox(height: 8),
          Text(currencyFormat.format(amount),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("PENDING REVIEW",
                style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildProfileCard(String name, String id) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryGreen.withOpacity(0.2),
            radius: 24,
            child: const Icon(Icons.person, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(id, style: const TextStyle(color: textGrey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black : textGrey, fontSize: 14)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
            color: isBold ? Colors.black : Colors.black87,
          )),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: () => _submitDecision(ComakerStatus.rejected),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: accentRed),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Reject",
                    style: TextStyle(color: accentRed, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => _submitDecision(ComakerStatus.approved),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Approve",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}