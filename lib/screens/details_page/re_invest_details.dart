import 'package:flutter/material.dart';

class ReinvestmentDetailsPage extends StatelessWidget {
  const ReinvestmentDetailsPage({super.key});

  // Theme Palette
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
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
          label: const Text("Back to List", style: TextStyle(color: Colors.grey)),
        ),
        title: const Text("Transaction ID: RI-2026-003", 
            style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: const Text("Active", style: TextStyle(color: successGreen, fontSize: 12)),
              backgroundColor: successGreen.withValues(alpha: 0.1),
              side: const BorderSide(color: successGreen),
              visualDensity: VisualDensity.compact,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Investment Overview
            _buildOverviewCard(),
            const SizedBox(height: 20),
            // 2. Middle Row: Projection and Ledger
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildGrowthProjectionCard()),
                const SizedBox(width: 20),
                Expanded(child: _buildTransactionLedgerCard()),
              ],
            ),
            const SizedBox(height: 20),
            // 3. Audit & Validation
            _buildAuditCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Investment Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoGridItem("Client Name", "Alice Greene", isLink: true),
              _infoGridItem("Method of Payment", "Cashier", isLink: true),
              _infoGridItem("Maturity Date", "March 12, 2027"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoGridItem("Re-investment Amount", "₱ 2,000.00", isBold: true),
              _infoGridItem("Effective Date", "March 12, 2026"),
              _infoGridItem("Interest Rate", "3.2% Annually"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthProjectionCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Growth Projection", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _projectionRow("Principal Amount", "₱ 2,000.00", "Total amount rolled over"),
          _projectionRow("Est. Annual Yield", "₱ 64.00", "Based on 3.2% rate", isGreen: true),
          _projectionRow("Maturity Date", "March 12, 2027", "12-month lock-in period"),
          const Divider(),
          _projectionRow("Projected Total", "₱ 2,064.00", "Principal + Interest", isBlue: true, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTransactionLedgerCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Transaction Ledger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _ledgerItem("Action Type", "Capital Re-allocation"),
          _ledgerItem("Previous Fund Status", "Closed / Re-invested"),
          _ledgerItem("New Portfolio Balance", "₱ 5,500.00", sub: "Excludes this transaction", isBold: true),
        ],
      ),
    );
  }

  Widget _buildAuditCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Audit & Validation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoGridItem("Processed By", "Admin [Manual Approval]"),
              _infoGridItem("Timestamp", "March 12, 2026, 10:45 AM"),
              _infoGridItem("Authorization", "AUTH-RI-992"),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Internal Notes", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: backgroundLight, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              "\"Client opted for automatic rollover of matured principal and 50% of earned dividends.\"",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
            ),
          )
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _cardContainer({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderLine),
    ),
    child: child,
  );

  Widget _infoGridItem(String label, String value, {bool isLink = false, bool isBold = false}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: isLink ? Colors.blue : darkBrown,
          fontSize: isBold ? 15 : 13,
        )),
      ],
    ),
  );

  Widget _projectionRow(String label, String value, String desc, {bool isGreen = false, bool isBlue = false, bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isGreen ? successGreen : (isBlue ? Colors.blue : darkBrown),
            )),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ],
    ),
  );

  Widget _ledgerItem(String label, String value, {String? sub, bool isBold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
        if (sub != null) Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    ),
  );
}