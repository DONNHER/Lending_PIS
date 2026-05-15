import 'package:flutter/material.dart';

class UpdateInterestRatePage extends StatelessWidget {
  const UpdateInterestRatePage({super.key});

  // Theme Palette
  static const Color darkBrown = Color(0xFF1F2937);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color borderLine = Color(0xFFE5E7EB);
  static const Color primaryBlue = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Update Interest Rate", 
            style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text("Export"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Current Rate and Update Form
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildCurrentRateCard(),
                  const SizedBox(height: 24),
                  _buildUpdateForm(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Audit Log History
            Expanded(
              flex: 1,
              child: _buildAuditLogCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Current Global Rate", 
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text("3.2%", 
              style: TextStyle(color: primaryBlue, fontSize: 48, fontWeight: FontWeight.bold)),
          const Text("Applied to 247 active loans", 
              style: TextStyle(color: primaryBlue, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUpdateForm() {
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
          const Text("Update Form", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          _formLabel("New Rate (%) *"),
          TextField(
            decoration: InputDecoration(
              hintText: "3.5",
              suffixText: "%",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 20),
          _formLabel("Effective Date *"),
          TextField(
            decoration: InputDecoration(
              hintText: "Select Date",
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 20),
          _formLabel("Change Reason *"),
          TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Explain why this rate is being updated...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Apply Changes", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                child: const Text("Clear"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAuditLogCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Audit Log - Rate History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Historical record of all rate changes (immutable)", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Table(
            border: const TableBorder(horizontalInside: BorderSide(color: borderLine)),
            children: [
              _auditHeader(),
              _auditRow("June 27, 2022", "3.0% → 3.2%", "Board Resolution #45 - Market adjustment"),
              _auditRow("January 15, 2022", "2.8% → 3.0%", "Quarterly review - Inflation adjustment"),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _formLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  TableRow _auditHeader() {
    return const TableRow(
      decoration: BoxDecoration(color: Color(0xFF1F2937)),
      children: [
        Padding(padding: EdgeInsets.all(12), child: Text("Date", style: TextStyle(color: Colors.white, fontSize: 12))),
        Padding(padding: EdgeInsets.all(12), child: Text("Rate Change", style: TextStyle(color: Colors.white, fontSize: 12))),
        Padding(padding: EdgeInsets.all(12), child: Text("Reason", style: TextStyle(color: Colors.white, fontSize: 12))),
      ],
    );
  }

  TableRow _auditRow(String date, String change, String reason) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(date, style: const TextStyle(fontSize: 13))),
        Padding(padding: const EdgeInsets.all(16), child: Text(change, style: const TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.bold))),
        Padding(padding: const EdgeInsets.all(16), child: Text(reason, style: const TextStyle(fontSize: 12, color: Colors.grey))),
      ],
    );
  }
}