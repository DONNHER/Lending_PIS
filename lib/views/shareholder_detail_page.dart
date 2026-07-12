import 'package:capstone_application/viewmodels/navigation_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/shareholder_detail_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/activity_log_table.dart';
import 'package:intl/intl.dart';
import 'add_share_capital_page.dart';
import 'loan_details_page.dart';

import 'add_loan_page.dart';

class ShareholderDetailPage extends StatefulWidget {
  final String shareholderId;
  final VoidCallback? onBack;
  const ShareholderDetailPage({super.key, required this.shareholderId, this.onBack});

  @override
  State<ShareholderDetailPage> createState() => _ShareholderDetailPageState();
}

class _ShareholderDetailPageState extends State<ShareholderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShareholderDetailViewModel>().loadShareholder(widget.shareholderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: const Text(
          'Shareholder Details', 
          style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
        ),
        actions: [
          Consumer<ShareholderDetailViewModel>(
            builder: (context, viewModel, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
              onPressed: () => viewModel.loadShareholder(widget.shareholderId),
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ShareholderDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final person = viewModel.shareholder;
          if (person == null) {
            return const Center(child: Text('Shareholder not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, person),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildInfoCard(person)),
                    const SizedBox(width: 24),
                    if (person.id.isNotEmpty)
                      Expanded(
                        flex: 3, 
                        child: SizedBox(
                          height: 350, // Fixed height to prevent IntrinsicHeight crash
                          child: _buildLoanSection(context, viewModel)
                        )
                      )
                    else
                      const Spacer(flex: 3),
                  ],
                ),
                const SizedBox(height: 24),
                if (person.id.isNotEmpty) ...[
                  _buildStats(viewModel),
                  const SizedBox(height: 24),
                ],
                _buildActivitySection(context, viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic person) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              person.firstName.isNotEmpty ? person.firstName[0] : '?',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.fullName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  person.email,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (person.id.isEmpty ? Colors.blue : const Color(0xFF10B981)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    person.id.isEmpty ? 'ADMINISTRATOR' : 'ACTIVE SHAREHOLDER',
                    style: TextStyle(
                      color: person.id.isEmpty ? Colors.blue : const Color(0xFF10B981), 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (person.id.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddShareCapitalPage(shareholder: person)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Share Capital'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC06C4D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                minimumSize: const Size(0, 48), // Fix: Prevents infinite width crash in Row
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoanSection(BuildContext context, ShareholderDetailViewModel viewModel) {
    final currencyFormat = NumberFormat.currency(symbol: '₱');
    final activeLoan = viewModel.loans.firstWhere(
      (l) => l['status']?.toString().toLowerCase() == 'active',
      orElse: () => null,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Loan Accounts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                if (activeLoan == null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddLoanPage(
                            shareholder: viewModel.shareholder!,
                          ),
                        ),
                      ).then((_) => viewModel.loadShareholder(widget.shareholderId));
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Request Loan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC06C4D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoanDetailsPage(
                            loanId: activeLoan['id'],
                            shareholderId: viewModel.shareholder!.id,
                          ),
                        ),
                      ).then((_) => viewModel.loadShareholder(widget.shareholderId));
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Loan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC06C4D),
                      side: const BorderSide(color: Color(0xFFC06C4D)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),
          if (viewModel.loans.isEmpty)
            const Expanded(
              child: Center(child: Text('No active loans found', style: TextStyle(color: AppTheme.textMuted))),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: viewModel.loans.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final loan = viewModel.loans[index];
                  final String rawId = loan['id']?.toString() ?? 'N/A';
                  final String displayId = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      'Loan ID: $displayId...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Principal: ${currencyFormat.format(double.tryParse(loan['principal_amount'].toString()) ?? 0.0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (loan['status'] == 'active' ? Colors.green : Colors.orange).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            loan['status'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: loan['status'] == 'active' ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoanDetailsPage(
                          loanId: loan['id'],
                          shareholderId: viewModel.shareholder!.id,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(dynamic person) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _infoTile(Icons.phone_outlined, 'Phone', person.phone ?? 'N/A'),
          const Divider(height: 32),
          _infoTile(Icons.location_on_outlined, 'Address', person.address ?? 'N/A'),
          const Divider(height: 32),
          _infoTile(Icons.credit_card_outlined, 'Shareholder ID', person.id),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(ShareholderDetailViewModel viewModel) {
    final person = viewModel.shareholder!;
    final currencyFormat = NumberFormat.currency(symbol: '₱');

    return Row(
      children: [
        Expanded(
          child: _statCard('Total Share Capital', currencyFormat.format(person.shareCapital), Icons.account_balance_wallet, Colors.orange),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard('Credit Score', person.creditScore.toStringAsFixed(1), Icons.star, Colors.blue),
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context, ShareholderDetailViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity Log',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close details
                    final nav = context.read<NavigationViewModel>();
                    final items = nav.getFilteredNavItems();
                    final index = items.indexWhere((item) => item.route == '/activity-logs');
                    if (index != -1) {
                      nav.navigateTo(index);
                    }
                  },
                  child: const Text('See all', style: TextStyle(color: Color(0xFFC06C4D), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: ActivityLogTable(
              logs: viewModel.auditTrail,
              isLoading: viewModel.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
