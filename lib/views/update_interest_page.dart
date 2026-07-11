import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/update_interest_viewmodel.dart';
import '../app_theme.dart';

class InterestManagementPage extends StatefulWidget {
  const InterestManagementPage({super.key});

  @override
  State<InterestManagementPage> createState() => _InterestManagementPageState();
}

class _InterestManagementPageState extends State<InterestManagementPage> {
  final _rateController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdateInterestViewModel>().loadData();
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Interest Management', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<UpdateInterestViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && !viewModel.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentRateCard(viewModel),
                const SizedBox(height: 24),
                const Text(
                  'Update Interest Rate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),
                _buildUpdateCard(context, viewModel),
                const SizedBox(height: 32),
                const Text(
                  'Rate History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 12),
                _buildHistoryList(viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentRateCard(UpdateInterestViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFC06C4D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC06C4D).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Interest Rate',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${(viewModel.currentRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Text(
                'per month',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, UpdateInterestViewModel viewModel) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'New Interest Rate (%)',
                hintText: 'e.g. 3.5',
                prefixIcon: Icon(Icons.percent_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Change',
                hintText: 'e.g. Market adjustment',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: viewModel.isLoading ? null : () => _handleUpdate(context, viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC06C4D),
                foregroundColor: Colors.white,
              ),
              child: viewModel.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update Rate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(UpdateInterestViewModel viewModel) {
    if (viewModel.history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No history available', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: viewModel.history.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = viewModel.history[index];
          final date = DateTime.parse(item['created_at']);
          final newRate = double.tryParse(item['new_rate'].toString()) ?? 0.0;
          final oldRate = double.tryParse(item['old_rate'].toString()) ?? 0.0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Text(
                  '${(oldRate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, decoration: TextDecoration.lineThrough),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${(newRate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFC06C4D)),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(item['reason'] ?? 'No reason provided', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text(DateFormat('MMM dd, yyyy HH:mm').format(date), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleUpdate(BuildContext context, UpdateInterestViewModel viewModel) async {
    final rateText = _rateController.text.trim();
    final reason = _reasonController.text.trim();

    if (rateText.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final newRate = double.tryParse(rateText);
    if (newRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid interest rate')),
      );
      return;
    }

    final success = await viewModel.updateRate(newRate / 100, reason);
    if (success && mounted) {
      _rateController.clear();
      _reasonController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interest rate updated successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update interest rate')),
      );
    }
  }
}
