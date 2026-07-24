import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/lending_models.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/shareholder_detail_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../app_theme.dart';
import '../widgets/activity_log_table.dart';
import 'add_share_capital_page.dart';

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
          Consumer2<ShareholderDetailViewModel, AuthViewModel>(
            builder: (context, viewModel, auth, _) {
              final person = viewModel.shareholder;
              return Row(
                children: [
                  if (person != null && person.userId != null && auth.currentUser?.role == UserRole.admin)
                    IconButton(
                      icon: const Icon(Icons.login_rounded, color: Color(0xFFC06C4D)),
                      onPressed: () => _handleImpersonate(context, person.userId!, person.fullName),
                      tooltip: 'Impersonate ${person.firstName}',
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
                    onPressed: () => viewModel.loadShareholder(widget.shareholderId),
                    tooltip: 'Refresh',
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ShareholderDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.shareholder == null) {
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

  Future<void> _handleImpersonate(BuildContext context, String userId, String fullName) async {
    try {
      final repo = context.read<UserRepository>();
      // Before calling impersonate, let's fetch the actual user to check status
      final user = await repo.getUserById(userId);

      if (user != null && user.status != UserStatus.active) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Cannot impersonate ${user.status.name} accounts. Please activate the user first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Fetch the target user's UserModel directly from Supabase instead of calling backend impersonate
      final targetUser = await repo.getUserById(userId);

      if (targetUser == null) {
        throw Exception('User profile not found.');
      }

      if (!mounted) return;

      final authModel = Provider.of<AuthViewModel>(context, listen: false);
      final nav = Provider.of<NavigationViewModel>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);

      await authModel.startImpersonation(targetUser);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Now impersonating $fullName'),
            backgroundColor: const Color(0xFFC06C4D),
          ),
        );
      }

      // Navigate to shareholder dashboard
      final route = authModel.dashboardRoute;
      if (route != null) {
        final navItems = nav.getFilteredNavItems();
        final idx = navItems.indexWhere((it) => it.route == route);
        if (idx != -1) nav.navigateTo(idx);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impersonation failed: $e'), backgroundColor: Colors.red),
      );
    }
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
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
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
                    color: (person.id.isEmpty ? Colors.blue : const Color(0xFF10B981)).withValues(alpha: 0.1),
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
    final activeLoanData = viewModel.activeLoan;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                if (activeLoanData == null)
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<NavigationViewModel>().navigateToLoanApplication(viewModel.shareholder!);
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
                      context.read<NavigationViewModel>().navigateToLoanDetails(
                        activeLoanData['id'],
                        viewModel.shareholder!.id,
                        loan: LoanModel.fromJson(activeLoanData),
                      );
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
                  final lData = viewModel.loans[index];
                  final String rawId = lData['id']?.toString() ?? 'N/A';
                  final String displayId = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      'Loan ID: $displayId...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Principal: ${currencyFormat.format(double.tryParse(lData['principal_amount'].toString()) ?? 0.0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (lData['status'] == 'active' ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lData['status'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: lData['status'] == 'active' ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ],
                    ),
                    onTap: () => context.read<NavigationViewModel>().navigateToLoanDetails(
                      lData['id'],
                      viewModel.shareholder!.id,
                      loan: LoanModel.fromJson(lData),
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
          if (person.idImageUrl != null && person.idImageUrl!.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('Verification Document', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBar(
                          title: const Text('ID Document'),
                          backgroundColor: Colors.white,
                          elevation: 0,
                        ),
                        Image.network(
                          person.idImageUrl!, 
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  'Image failed to load',
                                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please check if the Supabase storage bucket is Public.',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  image: DecorationImage(
                    image: NetworkImage(person.idImageUrl!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint('Error loading ID image: $exception');
                    },
                  ),
                ),
                child: person.idImageUrl != null 
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                        child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                      ),
                    )
                  : const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                softWrap: true,
              ),
            ],
          ),
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
            color: Colors.black.withValues(alpha: 0.02),
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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
