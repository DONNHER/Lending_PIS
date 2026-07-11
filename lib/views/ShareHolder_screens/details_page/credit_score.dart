import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import 'package:capstone_application/app_theme.dart';

class CreditScoreScreen extends StatelessWidget {
  const CreditScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;
    final shareholder = user?.shareholder;
    final creditScore = shareholder?.creditScore ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Credit Score', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildScoreCard(creditScore),
            const SizedBox(height: 32),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(double score) {
    Color scoreColor = _getScoreColor(score);
    String rating = _getScoreRating(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Text('Your Current Score', style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: score / 1000,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    score.toInt().toString(),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: scoreColor),
                  ),
                  Text(
                    rating,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scoreColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Scale: 300 - 850', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How it works', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 16),
        _buildInfoItem(Icons.history_rounded, 'Payment History', 'Your consistency in paying loans on time greatly impacts your score.'),
        _buildInfoItem(Icons.account_balance_wallet_outlined, 'Capital Contribution', 'Maintaining a steady share capital helps improve your financial standing.'),
        _buildInfoItem(Icons.timer_outlined, 'Credit Age', 'The longer you stay active with us, the better we can assess your reliability.'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 750) return Colors.green;
    if (score >= 650) return Colors.blue;
    if (score >= 550) return Colors.orange;
    return Colors.red;
  }

  String _getScoreRating(double score) {
    if (score >= 750) return 'Excellent';
    if (score >= 650) return 'Good';
    if (score >= 550) return 'Fair';
    return 'Poor';
  }
}
