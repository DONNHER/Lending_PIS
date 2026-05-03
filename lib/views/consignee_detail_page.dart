import 'package:capstone_application/views/consignee_form_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/consignee_model.dart';
import '../viewmodels/consignee_detail_viewmodel.dart';
import '../widgets/consignee_profile_card.dart';
import '../widgets/consignment_product_tile.dart';
import '../widgets/consignment_form_sheet.dart';

class ConsigneeDetailPage extends StatefulWidget {
  final ConsigneeModel consignee;

  const ConsigneeDetailPage({super.key, required this.consignee});

  @override
  State<ConsigneeDetailPage> createState() => _ConsigneeDetailPageState();
}

class _ConsigneeDetailPageState extends State<ConsigneeDetailPage> {
  late final ConsigneeDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Get the ViewModel from Provider and load data
    _viewModel = context.read<ConsigneeDetailViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadDetails(widget.consignee.id);
    });
  }

  // ─── Navigation to edit page ──────────────────────────────────────────
  void _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConsigneeFormPage(consignee: widget.consignee),
      ),
    );
    if (result == true && mounted) {
      _viewModel.loadDetails(widget.consignee.id);
      // Reload consignee data from parent list if needed
    }
  }

  // ─── Add consignment ──────────────────────────────────────────────────
  void _showAddConsignmentSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ConsignmentFormSheet(title: 'Add Consignment'),
    );

    if (result != null && mounted) {
      final success = await _viewModel.addConsignment(
        productId: result['product_id'] as String? ?? '',
        commissionRate: result['commission_rate'] as double,
        capitalPrice: result['capital_price'] as double,
      );

      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _viewModel.errorMessage ?? 'Failed to add consignment',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ─── Edit consignment ─────────────────────────────────────────────────
  void _showEditConsignmentSheet({
    required int consignmentId,
    required String productName,
    required double commissionRate,
    required double capitalPrice,
  }) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ConsignmentFormSheet(
        title: 'Edit Consignment',
        productName: productName,
        existingCommissionRate: commissionRate,
        existingCapitalPrice: capitalPrice,
      ),
    );

    if (result != null && mounted) {
      await _viewModel.updateConsignment(
        consignmentId: consignmentId,
        commissionRate: result['commission_rate'] as double,
        capitalPrice: result['capital_price'] as double,
      );
    }
  }

  // ─── Delete consignment ───────────────────────────────────────────────
  void _confirmDeleteConsignment(int consignmentId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove Consignment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('Remove "$productName" from this consignee?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _viewModel.deleteConsignment(consignmentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(widget.consignee.fullName),
        actions: [
          TextButton.icon(
            onPressed: _navigateToEdit,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Edit'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        ],
      ),
      body: Consumer<ConsigneeDetailViewModel>(
        builder: (context, viewModel, _) {
          // Loading state
          if (viewModel.isLoading && viewModel.consignee == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (viewModel.state == DetailViewState.error &&
              viewModel.consignee == null) {
            return _buildErrorState(viewModel);
          }

          final consignee = viewModel.consignee ?? widget.consignee;
          final products = viewModel.consignedProducts;

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                // Profile card
                SliverToBoxAdapter(
                  child: ConsigneeProfileCard(consignee: consignee),
                ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        const Text(
                          'Consignment Products',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showAddConsignmentSheet,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Product'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Products list or empty state
                if (products.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: AppTheme.textMuted,
                              size: 40,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No consigned products yet.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap "Add Product" to link a product.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((_, i) {
                      final item = products[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: ConsignmentProductTile(
                          product: item.product,
                          commissionRate: item.commissionRate,
                          capitalPrice: item.capitalPrice,
                          onTap:
                              null, // ← ADD THIS (or navigate somewhere if needed)
                          onEdit: () => _showEditConsignmentSheet(
                            consignmentId: item.consignmentId,
                            productName: item.product.productName,
                            commissionRate: item.commissionRate,
                            capitalPrice: item.capitalPrice,
                          ),
                          onDelete: () => _confirmDeleteConsignment(
                            item.consignmentId,
                            item.product.productName,
                          ),
                        ),
                      );
                    }, childCount: products.length),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ConsigneeDetailViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            viewModel.errorMessage ?? 'Error loading details',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => viewModel.loadDetails(widget.consignee.id),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
