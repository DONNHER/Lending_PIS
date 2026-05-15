import 'package:flutter/material.dart';

class FundReinvestScreen extends StatelessWidget {
  const FundReinvestScreen({super.key});

  // UI Theme Constants
  static const Color darkSlate = Color(0xFF1F2937);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color backgroundGrey = Color(0xFFF9FAFB);
  static const Color borderGrey = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text("Fund Re-invest Process", 
            style: TextStyle(color: darkSlate, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: successGreen),
              child: const Text("Done", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User Header Info
            _buildUserHeader(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Process Form
                Expanded(flex: 2, child: _buildReinvestmentForm()),
                const SizedBox(width: 24),
                // Right Column: Investment Description Sidebar
                Expanded(flex: 1, child: _buildInvestmentDescription()),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: const Row(
        children: [
          CircleAvatar(backgroundColor: borderGrey, child: Icon(Icons.person, color: Colors.grey)),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Alice Green", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("User Client", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Spacer(),
          Text("Fund ID: FND-2024-08", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReinvestmentForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("Select a Fund"),
          _buildDropdownPlaceholder("Select a Fund"),
          const SizedBox(height: 20),
          _fieldLabel("Amount"),
          _buildTextField(prefix: "₱", value: "2,000.00"),
          const SizedBox(height: 20),
          _fieldLabel("Payment Method"),
          _buildLinkButton("Cash"),
          const SizedBox(height: 20),
          _fieldLabel("Target Fund"),
          _buildTextField(value: "Share Capital", isReadOnly: true),
          const SizedBox(height: 24),
          _buildProcessStatusBox(),
          const SizedBox(height: 12),
          const Text("Dividend: Must Small Fund (Level-2)", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInvestmentDescription() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkSlate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Investment Description:", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("Active", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 24),
          _sidebarStat("Current Fund", "FND-2024-08"),
          _sidebarStat("Last Month Divid", "Aug 14, 2025"),
          _sidebarStat("End Date", "Aug 14, 2025"),
          _sidebarStat("Current Profit Fund", "₱ 150.00"),
          _sidebarStat("Principal", "₱ 2,000.00"),
          const Divider(color: Colors.white24, height: 32),
          _sidebarStat("Maturity", "₱ 2,150.00", isLarge: true),
        ],
      ),
    );
  }

  Widget _buildProcessStatusBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Green Growth Fund 2026", style: TextStyle(fontWeight: FontWeight.bold, color: darkSlate)),
          Text("(12-month tenure fund)", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: borderGrey))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: () {}, child: const Text("Cancel")),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: () {}, child: const Text("Set Schedule")),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Execute Re-investment", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---
  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
  );

  Widget _buildTextField({String? prefix, required String value, bool isReadOnly = false}) => TextField(
    readOnly: isReadOnly,
    controller: TextEditingController(text: value),
    decoration: InputDecoration(
      prefixText: prefix != null ? "$prefix " : null,
      filled: true,
      fillColor: isReadOnly ? backgroundGrey : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderGrey)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );

  Widget _buildLinkButton(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(border: Border.all(color: borderGrey), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [Text(text, style: const TextStyle(color: primaryBlue)), const Spacer(), const Icon(Icons.open_in_new, size: 14, color: primaryBlue)]),
  );

  Widget _buildDropdownPlaceholder(String hint) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(border: Border.all(color: borderGrey), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [Text(hint, style: const TextStyle(color: Colors.grey)), const Spacer(), const Icon(Icons.arrow_drop_down)]),
  );

  Widget _sidebarStat(String label, String value, {bool isLarge = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isLarge ? 18 : 14)),
      ],
    ),
  );
}