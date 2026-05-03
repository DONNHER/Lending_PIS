import 'package:capstone_application/viewmodels/consignee_detail_viewmodel.dart';
import 'package:capstone_application/views/consignee_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/consignee_model.dart';
import '../viewmodels/consignee_viewmodel.dart';
import '../widgets/consignee_card.dart';
import 'consignee_form_page.dart';

class ConsigneesPage extends StatefulWidget {
  const ConsigneesPage({super.key});

  @override
  State<ConsigneesPage> createState() => _ConsigneesPageState();
}

class _ConsigneesPageState extends State<ConsigneesPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load data when page first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await context.read<ConsigneeViewModel>().loadConsignees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load consignees: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ConsigneeFormPage()),
    );
    // Refresh if consignee was added successfully
    if (result == true && mounted) {
      _loadData();
    }
  }

  void _openEdit(ConsigneeModel consignee) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConsigneeFormPage(consignee: consignee),
      ),
    );
    // Refresh if consignee was updated
    if (result == true && mounted) {
      _loadData();
    }
  }

  // Replace or add this method
  void _openDetail(ConsigneeModel consignee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ConsigneeDetailViewModel>(),
          child: ConsigneeDetailPage(consignee: consignee),
        ),
      ),
    ).then((_) {
      // Refresh list when returning from detail
      context.read<ConsigneeViewModel>().loadConsignees();
    });
  }

  void _confirmDelete(ConsigneeModel consignee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Consignee',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${consignee.fullName}"?\n\n'
          'This will also permanently delete all uploaded documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog first

              if (!mounted) return;

              final viewModel = context.read<ConsigneeViewModel>();
              final success = await viewModel.deleteConsignee(consignee.id);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${consignee.fullName} deleted'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(viewModel.errorMessage ?? 'Delete failed'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<ConsigneeViewModel>(
                builder: (context, viewModel, _) {
                  // Loading state
                  if (viewModel.isLoading && viewModel.consignees.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Error state
                  if (viewModel.hasError && viewModel.consignees.isEmpty) {
                    return _buildErrorState(viewModel);
                  }

                  // Empty state
                  if (viewModel.consignees.isEmpty) {
                    return _buildEmptyState();
                  }

                  // List of consignees
                  return RefreshIndicator(
                    onRefresh: () => viewModel.loadConsignees(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: viewModel.consignees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final consignee = viewModel.consignees[i];
                        return ConsigneeCard(
                          consignee: consignee,
                          onTap: () => _openDetail(consignee),
                          onEdit: () => _openEdit(consignee),
                          onDelete: () => _confirmDelete(consignee),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Consignee',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Consignees',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (value) {
                context.read<ConsigneeViewModel>().setSearchQuery(value);
              },
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search consignee...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ConsigneeViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => viewModel.loadConsignees(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: AppTheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No consignees yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add your first consignee',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
