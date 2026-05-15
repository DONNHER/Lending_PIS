import 'package:flutter/material.dart';
import 'package:capstone_application/models/lending_models/shareholder.dart';

class UserProfilePage extends StatelessWidget {
  
  final ShareholderModel shareholder;

  const UserProfilePage({super.key, required this.shareholder});

  // Peaches & Cream Theme Colors
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color accentPeach = Color(0xFFF5E6DA);
  static const Color backgroundLight = Color(0xFFFDF7F2);
  static const Color borderLine = Color(0xFFE6DED8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("User Profile: ${shareholder.fullName}", 
          style: const TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_outlined, size: 18, color: darkBrown),
              label: const Text("Export", style: TextStyle(color: darkBrown)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: borderLine)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Row: Info Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildGeneralInfoCard()),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSummaryCard("Capital Contributions", "₱ 50,000.00", "Total Shares", "March 15, 2025"),
                      const SizedBox(width: 16),
                      _buildSummaryCard("Investment Portfolio", "₱ 15,750.00", "(estimated)", "ROI +5.2%"),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: _buildLoanDetailsCard()),
              ],
            ),

            const SizedBox(height: 32),

            // 2. Recent Activity Log Header with "See all" inline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Activity Log",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkBrown),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("See all", 
                    style: TextStyle(color: terracotta, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. Activity Table (Dark Theme)
            _buildDarkActivityTable(),
            
            const SizedBox(height: 24),
            
            // Close Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: borderLine)),
                child: const Text("Close", style: TextStyle(color: darkBrown)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // General Info Card
  Widget _buildGeneralInfoCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("User's Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(height: 32),
          _infoLabel("Full Name", shareholder.fullName),
          _infoLabel("Email", shareholder.email),
          _infoLabel("Contact", shareholder.contact),
          _infoLabel("Member Since", shareholder.memberSince),
          _infoLabel("Status", "Active Member", isStatus: true),
          _infoLabel("Credit Score", "750 - Excellent", isScore: true),
        ],
      ),
    );
  }

  // Loan Details Card with Progress Bar
  Widget _buildLoanDetailsCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Loan Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("₱ 3,000.00", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Outstanding Balance", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 32),
          _infoLabel("Active Loans", "1"),
          _infoLabel("Repayment Due", "April 30, 2025"),
          const SizedBox(height: 16),
          const Text("Payment Progress", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: 0.7, backgroundColor: borderLine, color: Colors.green, minHeight: 8),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text("₱ 7,000.00 paid", style: TextStyle(fontSize: 11)), Text("70%", style: TextStyle(fontSize: 11))],
          ),
        ],
      ),
    );
  }

  // Dark Activity Table
  Widget _buildDarkActivityTable() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowHeight: 48,
          columns: const [
            DataColumn(label: Text('Date', style: TextStyle(color: Colors.grey))),
            DataColumn(label: Text('Action', style: TextStyle(color: Colors.grey))),
            DataColumn(label: Text('Description', style: TextStyle(color: Colors.grey))),
            DataColumn(label: Text('AmountStatus', style: TextStyle(color: Colors.grey))),
          ],
          rows: [
            _darkRow("Apr 20, 2025", "Loan Payment", "Monthly Installment", "₱ 500.00", "Completed"),
            _darkRow("Apr 15, 2025", "Share Purchase", "Capital contribution", "₱ 5,000.00", "Completed"),
            _darkRow("Apr 10, 2025", "Dividend", "Quarterly dividend", "₱ 750.00", "Completed"),
          ],
        ),
      ),
    );
  }

  // UI Helper Components
  DataRow _darkRow(String date, String action, String desc, String amt, String status) {
    return DataRow(cells: [
      DataCell(Text(date, style: const TextStyle(color: Colors.white))),
      DataCell(Text(action, style: const TextStyle(color: Colors.white))),
      DataCell(Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      DataCell(Row(children: [
        Text(amt, style: const TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        Text(status, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
      ])),
    ]);
  }

  Widget _cardContainer({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderLine)),
    child: child,
  );

  Widget _buildSummaryCard(String title, String val, String sub, String footer) => _cardContainer(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 8),
      Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      const SizedBox(height: 8),
      Text(footer, style: TextStyle(color: footer.contains('+') ? Colors.green : Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _infoLabel(String label, String value, {bool isStatus = false, bool isScore = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(value, style: TextStyle(
        fontWeight: FontWeight.w600, 
        color: isStatus ? Colors.green : (isScore ? Colors.green : darkBrown)
      )),
    ]),
  );
}