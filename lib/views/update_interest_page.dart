import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/update_interest_viewmodel.dart';
import '../app_theme.dart';

class InterestManagementPage extends StatefulWidget {
  const InterestManagementPage({super.key});

  @override
  State<InterestManagementPage> createState() => _InterestManagementPageState();
}

class _InterestManagementPageState extends State<InterestManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdateInterestViewModel>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryBrown = Color(0xFFC06C4D);
    const background = Color(0xFFFDF8F5);
    const textDark = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.read<NavigationViewModel>().clearAdminSettings(),
        ),
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFC06C4D),
                child: Icon(Icons.percent_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Interest Management',
                      style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('System Settings',
                      style: TextStyle(color: primaryBrown, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Consumer<UpdateInterestViewModel>(
            builder: (context, viewModel, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded, color: primaryBrown),
              onPressed: viewModel.refresh,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<UpdateInterestViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && !viewModel.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: primaryBrown));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _MainContent(viewModel: viewModel),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: _Sidebar(viewModel: viewModel),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final UpdateInterestViewModel viewModel;

  const _MainContent({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    const primaryBrown = Color(0xFFC06C4D);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Financial Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _infoRow('Current Interest Rate', '${(viewModel.currentRate * 100).toStringAsFixed(1)}%',
                  valueColor: primaryBrown),
              _infoRow('Rate Type', 'Monthly Periodic'),
              _infoRow('Calculation Method', 'Simple Interest'),
              _infoRow('Target Products', 'All Loan Types'),
              const Divider(height: 40),
              const Text(
                'Adjustment Policy',
                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Interest rate changes are applied to new loan requests only. Existing active loans will maintain their original rates until fully paid.',
                style: TextStyle(color: Color(0xFF1F2937), fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
            Text(value,
                style: TextStyle(
                    color: valueColor ?? const Color(0xFF1F2937), fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      );
}

class _Sidebar extends StatelessWidget {
  final UpdateInterestViewModel viewModel;

  const _Sidebar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 650,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFF32211A), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          _ActionButton(Icons.edit_rounded, 'Update rate', () => _showUpdateDialog(context, viewModel)),
          _ActionButton(Icons.history_rounded, 'Export history', () {}),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rate History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: viewModel.sortOrder,
                dropdownColor: const Color(0xFF32211A),
                underline: const SizedBox(),
                icon: const Icon(Icons.sort_rounded, color: Colors.white54, size: 16),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                items: ['Newest', 'Oldest']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) viewModel.setSortOrder(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: viewModel.history.isEmpty
                ? const Center(child: Text('No history yet', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: viewModel.history.length,
                    itemBuilder: (context, index) {
                      final item = viewModel.history[index];
                      final dateStr = item['created_at'] ?? item['effective_date'] ?? DateTime.now().toIso8601String();
                      final date = DateTime.parse(dateStr);
                      final rate = (double.tryParse(item['new_rate'].toString()) ?? 0.0) * 100;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('MMM dd, yyyy').format(date),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('${rate.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                        color: Color(0xFFC06C4D), fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['reason'] ?? 'System adjustment',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(color: Colors.white24, height: 32),
          _PaginationControl(viewModel: viewModel),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, UpdateInterestViewModel viewModel) {
    final rateController = TextEditingController(text: (viewModel.currentRate * 100).toStringAsFixed(1));
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Interest Rate', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'New Interest Rate (%)',
                  hintText: 'e.g. 3.5',
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Rate is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for Change',
                  hintText: 'e.g. Market adjustment',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newRate = double.tryParse(rateController.text);
                if (newRate == null) return;

                final success = await viewModel.updateRate(newRate / 100, reasonController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Interest rate updated' : 'Update failed'),
                      backgroundColor: success ? Colors.green : AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC06C4D),
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 48),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFC06C4D), size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
}

class _PaginationControl extends StatelessWidget {
  final UpdateInterestViewModel viewModel;
  const _PaginationControl({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
          onPressed: viewModel.currentPage > 1 ? () => viewModel.setPage(viewModel.currentPage - 1) : null,
        ),
        Text(
          'Page ${viewModel.currentPage} of ${viewModel.lastPage}',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          onPressed: viewModel.currentPage < viewModel.lastPage ? () => viewModel.setPage(viewModel.currentPage + 1) : null,
        ),
      ],
    );
  }
}
