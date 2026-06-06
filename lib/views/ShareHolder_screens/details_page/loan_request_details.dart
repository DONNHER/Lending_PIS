import 'package:flutter/material.dart';

class LoanRequestStatusScreen extends StatelessWidget {
  final String? loanId;
  final bool isPending;
  final String? borrowerName;

  const LoanRequestStatusScreen({
    super.key,
    this.loanId,
    this.isPending = false,
    this.borrowerName,
  });

  // Design System Colors
  static const Color primaryGreen = Color(0xFF66FF66);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color textGrey = Color(0xFF9CA3AF);

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
        title: Text(isPending ? "Loan Request Details" : "Loan Details",
            style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isPending ? _buildPendingStatusCard() : _buildPaymentProgressCard(),
                  const SizedBox(height: 24),
                  const Text("Breakdown",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDetailRow("Principal Amount", isPending ? "₱2,000.00" : "₱10,000.00"),
                  _buildDetailRow("Interest", isPending ? "₱46.00" : "₱230.00"),
                  _buildDetailRow("Processing Fee", isPending ? "₱50.00" : "₱150.00"),
                  const Divider(height: 32),
                  _buildDetailRow("Total Repayable", isPending ? "₱2,096.00" : "₱10,380.00", isBold: true),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(isPending ? "Requested Amount" : "Upcoming Payment", style: const TextStyle(color: textGrey, fontSize: 14)),
          const SizedBox(height: 8),
          Text(isPending ? "₱2,000.00" : "₱1,730.00",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isPending ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPending ? "Awaiting Co-maker" : "Due in 5 days",
              style: TextStyle(
                color: isPending ? Colors.blue.shade700 : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStatusCard() {
    final String statusDescription = borrowerName != null
        ? "Loan request submitted by $borrowerName. Your request is safely logged and is awaiting verification from the designated co-maker."
        : "Your request is safely logged and is waiting on verification from your designated co-maker.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: Colors.blue, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Application Submitted", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  statusDescription,
                  style: const TextStyle(color: textGrey, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Payment Progress", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("3 of 6 months", style: TextStyle(color: textGrey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.5,
              minHeight: 8,
              backgroundColor: Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _progressInfo("Paid", "₱5,190.00"),
              _progressInfo("Left", "₱5,190.00"),
            ],
          )
        ],
      ),
    );
  }

  Widget _progressInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textGrey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black : textGrey)),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold ? 16 : 14,
          )),
        ],
      ),
    );
  }
}
