import 'package:flutter/material.dart';

class LoanEvaluationPage extends StatelessWidget {
  const LoanEvaluationPage({super.key});

  static const Color darkBrown = Color(0xFF1F2937);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color successGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Alice Green", style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold, fontSize: 18)),
            const Text("Loan Evaluation", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Evaluation Snapshot
                Expanded(
                  flex: 2,
                  child: _buildEvaluationSnapshot(),
                ),
                const SizedBox(width: 20),
                // Risk & Metrics Sidebar
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildRiskAssessmentCard(),
                      const SizedBox(height: 20),
                      _buildEvaluationMetricsCard(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildEvaluationLog(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationSnapshot() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Loan Application Profile & Evaluation Snapshot", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricTile("Requested Amount", "₱ 5,000.00", isBold: true),
              _metricTile("Interest Rate", "5% per annum"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricTile("Tenure", "12 months"),
              _metricTile("Credit Score", "750 (Good)", color: successGreen),
            ],
          ),
          const SizedBox(height: 20),
          _metricTile("Purpose", "Business Expansion"),
          const SizedBox(height: 30),
          // Placeholder for the bar chart
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.bar_chart, size: 100, color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Risk Assessment & Recommendation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 16),
          const Text("Risk Level", style: TextStyle(color: Colors.grey, fontSize: 11)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: const Text("Low Risk", style: TextStyle(color: successGreen, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(height: 16),
          _sidebarInfo("Recommendation", "Approve"),
          _sidebarInfo("Priority", "N/A"),
        ],
      ),
    );
  }

  Widget _buildEvaluationMetricsCard() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Evaluation Metrics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 16),
          _rowMetric("Repayment Capacity", "85%", color: successGreen),
          _rowMetric("Debt-to-Income", "30%"),
          _rowMetric("Collateral Value", "₱ 0,000"),
          const Divider(),
          _rowMetric("Final Score", "8/10", color: Colors.blue, isBold: true),
        ],
      ),
    );
  }

  Widget _buildEvaluationLog() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Evaluation Log", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _logItem("Documents verified", "2 hours ago"),
          _logItem("Credit check completed", "5 hours ago"),
          _logItem("Application submitted", "1 day ago"),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Colors.red)),
          child: const Text("Reject", style: TextStyle(color: Colors.red)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text("Approve & Process", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // --- Helpers ---
  Widget _cardContainer({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
    child: child,
  );

  Widget _metricTile(String label, String value, {bool isBold = false, Color? color}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: isBold ? 18 : 14, color: color ?? darkBrown)),
    ],
  );

  Widget _sidebarInfo(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    ),
  );

  Widget _rowMetric(String label, String value, {Color? color, bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.bold, color: color ?? darkBrown)),
      ],
    ),
  );

  Widget _logItem(String text, String time) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: successGreen, size: 14),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const Spacer(),
        Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    ),
  );
}