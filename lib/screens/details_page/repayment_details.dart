import 'package:flutter/material.dart';

class RepaymentDetailsPage extends StatelessWidget {
  const RepaymentDetailsPage({super.key});

  // Peaches & Cream Theme Colors
  static const Color darkBrown = Color(0xFF1F2937); // Darker blue-grey for headers
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color backgroundLight = Color(0xFFFDF7F2);
  static const Color borderLine = Color(0xFFE6DED8);
  static const Color successGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Repayment Details: ID RP-2025-002", 
                style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold, fontSize: 20)),
            Text("Full record and ledger", 
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: OutlinedButton(onPressed: () {}, child: const Text("Add new record")),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: ElevatedButton(
              onPressed: () {}, 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
              child: const Text("Edit this entry", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Payment Info and History
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildPaymentInfoCard(),
                  const SizedBox(height: 24),
                  _buildRecentRepaymentList(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Distribution and Status
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildDistributionCard(),
                  const SizedBox(height: 24),
                  _buildStatusCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  // 1. Repayment Payment Information Card
  Widget _buildPaymentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Repayment Payment Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoTile("Borrower", "Juan Dela Cruz"),
              _infoTile("Payment Date", "Jan 15, 2025, 08:30 AM"),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoTile("Loan ID", "LA-2024-001", isLink: true),
              _infoTile("Payment Method", "Bank Transfer"),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoTile("Loan Amount", "₱ 10,000.00"),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Status", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: successGreen)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 14, color: successGreen),
                          SizedBox(width: 4),
                          Text("Completed", style: TextStyle(color: successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoTile("Repayment Method", "Full Payment"),
              _infoTile("Total Repayment", "₱ 10,500.00", isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Recent Repayment List (Table)
  Widget _buildRecentRepaymentList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderLine)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Recent Repayment List", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          DataTable(
            columnSpacing: 40,
            columns: const [
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Payment ID")),
              DataColumn(label: Text("Amount")),
              DataColumn(label: Text("Method")),
              DataColumn(label: Text("Status")),
            ],
            rows: [
              _repaymentRow("Jan 15, 2025", "RP-001", "₱ 3,500.00", "Cash"),
              _repaymentRow("Dec 15, 2024", "RP-002", "₱ 3,500.00", "Cash"),
              _repaymentRow("Nov 15, 2024", "RP-003", "₱ 3,500.00", "Cash"),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Distribution Card (Dark Theme Sidebar)
  Widget _buildDistributionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Repayment Distribution", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _distributionItem("Small Fund A", "40%", "₱ 4,200.00"),
          const Divider(color: Colors.white24, height: 32),
          _distributionItem("Small Fund B", "30%", "₱ 3,150.00"),
          const Divider(color: Colors.white24, height: 32),
          _distributionItem("Small Fund C", "30%", "₱ 3,150.00"),
        ],
      ),
    );
  }

  // 4. Payment Status Checklist
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderLine)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _statusStep("Fully Repaid", "All payments completed", true),
          _statusStep("Verified", "Payment confirmed", true),
          _statusStep("Closed", "Loan account closed", true),
        ],
      ),
    );
  }

  // Helpers
  Widget _infoTile(String label, String value, {bool isLink = false, bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isLink ? Colors.blue : darkBrown,
            fontSize: isBold ? 16 : 14,
          )),
        ],
      ),
    );
  }

  DataRow _repaymentRow(String date, String id, String amount, String method) {
    return DataRow(cells: [
      DataCell(Text(date)),
      DataCell(Text(id, style: const TextStyle(color: Colors.blue))),
      DataCell(Text(amount, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(method)),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: const Text("Completed", style: TextStyle(color: successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
      )),
    ]);
  }

  Widget _distributionItem(String title, String percent, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            Text(percent, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Paid Amount:", style: TextStyle(color: Colors.grey, fontSize: 11)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Remaining:", style: TextStyle(color: Colors.grey, fontSize: 11)),
            Text("₱ 0.00", style: TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _statusStep(String title, String sub, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: isDone ? successGreen : Colors.grey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: borderLine))),
      child: Row(
        children: [
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_outlined), label: const Text("Download")),
          const SizedBox(width: 12),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.print_outlined), label: const Text("Print")),
          const Spacer(),
          OutlinedButton(
            onPressed: () {}, 
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            child: const Text("Delete Record"),
          ),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: () {}, child: const Text("Close")),
        ],
      ),
    );
  }
}