import 'package:flutter/material.dart';

class LoanTransactionDetailsPage extends StatelessWidget {
  const LoanTransactionDetailsPage({super.key});

  // Custom palette based on your "Peaches and Cream" theme
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color backgroundLight = Color(0xFFFDF7F2);
  static const Color borderLine = Color(0xFFE6DED8);
  static const Color successGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Loan Transaction Details: ID LA-2025-05-01-AI",
          style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0, top: 10, bottom: 10),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(side: const BorderSide(color: borderLine)),
              child: const Text("Export", style: TextStyle(color: darkBrown)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Top Section: Info Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildClientLoanIDCard()),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: _buildPerformanceMetricsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildReferenceLinksSidebar()),
              ],
            ),
            const SizedBox(height: 24),
            // Bottom Section: History Table
            _buildRecentLoanHistory(),
            const SizedBox(height: 24),
            // Footer Action
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: borderLine),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text("Close", style: TextStyle(color: darkBrown)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientLoanIDCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Client and Loan ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 32),
          _infoLabel("Client Name", "Jane Smith"),
          _infoLabel("User ID", "SH-2024-017-JS [Admin]"),
          _infoLabel("Loan ID", "LA-2025-05-01-AI", isLink: true),
          const Text(
            "A list of the client and information on the loan, this can be a list form or a brief display.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _infoLabel("Loan Issued Date", "May 1, 2025"),
          _infoLabel("Next Payment Due", "June 1, 2025"),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Loan Performance & Metrics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 32),
          _metricRow("Total Principal", "₱ 50,000.00", isBold: true),
          _metricRow("Interest Rate", "10.00%"),
          const SizedBox(height: 16),
          const Text("Repayment Progress", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          const Text("32.00%", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.32,
            backgroundColor: borderLine,
            color: Colors.blue,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          _metricRow("Tenure", "12 months"),
          _metricRow("Funds Issued", "Multiple"),
        ],
      ),
    );
  }

  Widget _buildReferenceLinksSidebar() {
    return Column(
      children: [
        _cardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Reference Links", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _linkItem("Payment Record"),
              _linkItem("User Agreement and Terms"),
              _linkItem("Credit-Debit Report"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: successGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              "Active Loan",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLoanHistory() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Recent Loan History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(3),
              4: FlexColumnWidth(2),
              5: FlexColumnWidth(1.5),
            },
            children: [
              _tableHeader(),
              _tableRow("LA-2025-05-01-AI", "Jane Smith", "May 1, 2025", "₱ 50,000.00 / 10.00%", "12 months", "Active"),
              _tableRow("LA-2024-12-15-JS", "Jane Smith", "Dec 15, 2024", "₱ 30,000.00 / 8.50%", "6 months", "Closed"),
              _tableRow("LA-2024-06-20-JS", "Jane Smith", "Aug 20, 2024", "₱ 25,000.00 / 9.00%", "12 months", "Closed"),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _cardContainer({required Widget child}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderLine),
    ),
    child: child,
  );

  Widget _infoLabel(String label, String value, {bool isLink = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isLink ? Colors.blue : darkBrown,
        )),
      ],
    ),
  );

  Widget _metricRow(String label, String value, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          fontSize: isBold ? 20 : 14,
        )),
      ],
    ),
  );

  Widget _linkItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: InkWell(
      onTap: () {},
      child: Row(
        children: [
          const Icon(Icons.open_in_new, size: 14, color: Colors.blue),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.blue, fontSize: 13)),
        ],
      ),
    ),
  );

  TableRow _tableHeader() => const TableRow(
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderLine))),
    children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Loan ID", style: TextStyle(color: Colors.grey, fontSize: 12))),
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Client Name", style: TextStyle(color: Colors.grey, fontSize: 12))),
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Issue Date", style: TextStyle(color: Colors.grey, fontSize: 12))),
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Principal/Interest Rate", style: TextStyle(color: Colors.grey, fontSize: 12))),
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Tenure", style: TextStyle(color: Colors.grey, fontSize: 12))),
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Status", style: TextStyle(color: Colors.grey, fontSize: 12))),
    ],
  );

  TableRow _tableRow(String id, String name, String date, String rates, String tenure, String status) => TableRow(
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: borderLine))),
    children: [
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(id, style: const TextStyle(color: Colors.blue, fontSize: 13))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(name, style: const TextStyle(fontSize: 13))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(date, style: const TextStyle(fontSize: 13))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(rates, style: const TextStyle(fontSize: 13))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(tenure, style: const TextStyle(fontSize: 13))),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: status == "Active" ? successGreen.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(status, textAlign: TextAlign.center, style: TextStyle(
            color: status == "Active" ? successGreen : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          )),
        ),
      ),
    ],
  );
}