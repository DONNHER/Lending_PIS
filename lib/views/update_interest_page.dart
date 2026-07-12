import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/update_interest_viewmodel.dart';
import '../app_theme.dart';
import '../widgets/rate_history_table.dart';
import '../widgets/page_turner.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Interest Management', 
          style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold)
        ),
        actions: [
          Consumer<UpdateInterestViewModel>(
            builder: (context, viewModel, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFC06C4D)),
              onPressed: viewModel.refresh,
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<UpdateInterestViewModel>(
        builder: (context, viewModel, child) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [
                  _buildActionBar(viewModel),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrentRateCard(context, viewModel),
                          const SizedBox(height: 24),
                          _buildFilterDropdown(
                            label: 'Sort By',
                            value: viewModel.sortOrder,
                            items: ['Newest', 'Oldest'],
                            onChanged: (val) {
                              if (val != null) viewModel.setSortOrder(val);
                            },
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Rate History',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 16),
                          _buildHistoryTable(viewModel),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(UpdateInterestViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          _buildFilterDropdown(
            label: 'Sort By',
            value: viewModel.sortOrder,
            items: ['Newest', 'Oldest'],
            onChanged: (val) {
              if (val != null) viewModel.setSortOrder(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            items: items.map((String v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRateCard(BuildContext context, UpdateInterestViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
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
          ElevatedButton.icon(
            onPressed: () => _showUpdateDialog(context, viewModel),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Update Rate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFC06C4D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(UpdateInterestViewModel viewModel) {
    return Container(
      height: 500,
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
        children: [
          Expanded(
            child: RateHistoryTable(
              history: viewModel.history ?? [],
              isLoading: viewModel.isLoading,
            ),
          ),
          PageTurner(
            currentPage: viewModel.currentPage,
            totalPages: viewModel.lastPage,
            totalRows: viewModel.totalRows,
            rowsPerPage: viewModel.rowsPerPage,
            onPageChanged: viewModel.setPage,
            onRowsPerPageChanged: (val) {
              if (val != null) viewModel.setRowsPerPage(val);
            },
          ),
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
