import 'package:capstone_application/views/consignment_form_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/consignment_products_repository.dart';
import '../repositories/daily_inventory_repository.dart';
import '../viewmodels/consignment_detail_viewmodel.dart';
import '../viewmodels/consignment_products_viewmodels.dart';
import '../widgets/consignment_product_tile.dart';
import 'package:capstone_application/views/consignment_detail_page.dart';

class ConsignmentProductsPage extends StatefulWidget {
  const ConsignmentProductsPage({super.key});

  @override
  State<ConsignmentProductsPage> createState() =>
      _ConsignmentProductsPageState();
}

class _ConsignmentProductsPageState extends State<ConsignmentProductsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsignmentProductsViewModel>().loadConsignments();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDetail(ConsignmentWithDetails item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: context.read<ConsignmentProductsViewModel>(),
            ),
            ChangeNotifierProvider(
              create: (_) => ConsignmentDetailViewModel(
                context.read<ConsignmentProductsRepository>(),
                context.read<DailyInventoryRepository>(),
              ),
            ),
          ],
          child: ConsignmentDetailPage(consignmentId: item.consignment.id),
        ),
      ),
    );
  }

  void _toggleStatus(ConsignmentWithDetails item) {
    context.read<ConsignmentProductsViewModel>().toggleStatus(
          item.product.id,
          item.product.isActive,
        );
  }

  void _confirmDelete(ConsignmentWithDetails item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Consignment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${item.product.productName}" from this consignee?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<ConsignmentProductsViewModel>()
                  .deleteConsignment(item.consignment.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ConsignmentFormPage()),
          );
          if (result == true && mounted) {
            context.read<ConsignmentProductsViewModel>().loadConsignments();
          }
        },
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Consignment',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title — no icon next to it
          const Text(
            'Consignment Products',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          // Full-width search field directly below the title
          TextField(
            controller: _searchCtrl,
            onChanged: (value) => context
                .read<ConsignmentProductsViewModel>()
                .setSearchQuery(value),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search consignment...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.textMuted, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.secondary.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppTheme.secondary.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<ConsignmentProductsViewModel>(
      builder: (context, vm, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: ['All', 'Active', 'Inactive'].map((filter) {
              final selected = vm.statusFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => vm.setStatusFilter(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.secondary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppTheme.secondary
                            : AppTheme.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<ConsignmentProductsViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.allConsignments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.state == ProductsViewState.error &&
            vm.allConsignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                Text(vm.errorMessage ?? 'Error loading products',
                    style: const TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => vm.loadConsignments(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (vm.consignments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handshake_outlined,
                    size: 48, color: AppTheme.textMuted),
                SizedBox(height: 12),
                Text('No consignment products found.',
                    style: TextStyle(color: AppTheme.textMuted)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => vm.loadConsignments(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: vm.consignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = vm.consignments[i];
              return ConsignmentProductTile(
                product: item.product,
                commissionRate: item.consignment.commissionRate,
                capitalPrice: item.consignment.capitalPrice,
                onTap: () => _openDetail(item),
                onToggle: () => _toggleStatus(item),
                onEdit: null, // wire up when edit form is ready
                onDelete: () => _confirmDelete(item),
              );
            },
          ),
        );
      },
    );
  }
}