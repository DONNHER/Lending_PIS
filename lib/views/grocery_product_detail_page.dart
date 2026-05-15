import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/grocery_batch_model.dart';
import '../repositories/grocery_repository.dart';
import '../viewmodels/grocery_viewmodel.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/grocery_batch_card.dart';
import 'add_edit_grocery_product_page.dart';
import 'add_edit_grocery_batch_page.dart';

class GroceryProductDetailPage extends StatefulWidget {
  // ✅ FIX: store only the grocery ID, not the full object.
  //    The old code kept a reference to the original `widget.grocery` forever,
  //    so even after `loadGroceries()` ran the page still showed stale data
  //    (old batches, old stock count, old prices).  By looking up the current
  //    object from the ViewModel on every build we always see fresh data.
  final String groceryId;

  const GroceryProductDetailPage({super.key, required this.groceryId});

  @override
  State<GroceryProductDetailPage> createState() =>
      _GroceryProductDetailPageState();
}

class _GroceryProductDetailPageState extends State<GroceryProductDetailPage>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  int _tab = 0;
  late final TabController _tabController;
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        
        setState(() => _tab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ FIX: always resolve the grocery from the live ViewModel list
  GroceryWithDetails? _resolveGrocery(GroceryViewModel vm) {
    try {
      return vm.allGroceries.firstWhere(
        (g) => g.grocery.id == widget.groceryId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _addBatch(GroceryWithDetails g) async {
    final result = await Navigator.push<GroceryBatchModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddEditGroceryBatchPage(productName: g.product.productName),
      ),
    );
    if (result != null && mounted) {
      await context.read<GroceryViewModel>().addBatch(
            grocery: g,
            capitalPrice: result.capitalPrice,
            quantity: result.originalQuantity,
            purchaseDate: result.purchaseDate,
            expirationDate: result.expirationDate,
          );
    }
  }

  Future<void> _editBatch(GroceryWithDetails g, GroceryBatchModel b) async {
    final result = await Navigator.push<GroceryBatchModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditGroceryBatchPage(
          productName: g.product.productName,
          batch: b,
        ),
      ),
    );
    if (result != null && mounted) {
      await context.read<GroceryViewModel>().updateBatch(
            grocery: g,
            batch: b,
            capitalPrice: result.capitalPrice,
            quantity: result.originalQuantity,
            purchaseDate: result.purchaseDate,
            expirationDate: result.expirationDate,
          );
    }
  }

  void _deleteBatch(GroceryWithDetails g, GroceryBatchModel b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Batch',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Remove batch purchased on '
            '${b.purchaseDate.toLocal().toString().split(' ')[0]}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context
                  .read<GroceryViewModel>()
                  .deleteBatch(grocery: g, batch: b);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GroceryViewModel>();
    final g = _resolveGrocery(vm);

    // Product was deleted while we were on this page
    if (g == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Detail')),
        body: const Center(child: Text('Product no longer exists.')),
      );
    }

    final totalStock = vm.getTotalStock(g);
    final avgCost = vm.getAvgCostPrice(g);
    final isActive = g.product.isActive;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Sliver App Bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderBackground(
                productName: g.product.productName,
                isActive: isActive,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                tooltip: 'Edit product',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: vm,
                        child: AddEditGroceryProductPage(grocery: g),
                      ),
                    ),
                  );
                  // ViewModel already calls loadGroceries() inside updateProduct,
                  // so the page rebuilds automatically via context.watch above.
                },
              ),
              _StatusToggleButton(
                isActive: isActive,
                onTap: () => vm.toggleProductStatus(g),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Stats Row ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _StatPill(
                    label: 'Stock',
                    value: '$totalStock',
                    color: totalStock == 0 ? AppTheme.error : AppTheme.success,
                    icon: Icons.inventory_2_rounded,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Selling',
                    value: '₱${g.product.sellingPrice.toStringAsFixed(2)}',
                    color: AppTheme.primary,
                    icon: Icons.sell_rounded,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Avg Cost',
                    value: '₱${avgCost.toStringAsFixed(2)}',
                    color: AppTheme.secondary,
                    icon: Icons.price_change_rounded,
                  ),
                ],
              ),
            ),
          ),

          // ── Barcode chip ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_rounded,
                      size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    g.product.barcode,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab bar ────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(icon: Icon(Icons.layers_rounded), text: 'Batches'),
                  Tab(
                      icon: Icon(Icons.swap_horiz_rounded),
                      text: 'Movements'),
                ],
              ),
            ),
          ),
        ],

        // ── Tab bodies ─────────────────────────────────────────────────
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Batches tab ──────────────────────────────────────────
            _BatchesTab(
              g: g,
              onAdd: () => _addBatch(g),
              onEdit: (b) => _editBatch(g, b),
              onDelete: (b) => _deleteBatch(g, b),
            ),

            // ── Movements tab ────────────────────────────────────────
            MovementsPlaceholder(productName: g.product.productName),
          ],
        ),
      ),
    );
  }
}

// ─── Batches Tab ─────────────────────────────────────────────────────────────

class _BatchesTab extends StatelessWidget {
  final GroceryWithDetails g;
  final VoidCallback onAdd;
  final void Function(GroceryBatchModel) onEdit;
  final void Function(GroceryBatchModel) onDelete;

  const _BatchesTab({
    required this.g,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final batches = g.batches;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${batches.length} batch${batches.length == 1 ? '' : 'es'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                AddButton(label: 'Add Batch', onTap: onAdd),
              ],
            ),
          ),
        ),
        batches.isEmpty
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(message: 'No batches yet. Add one!'),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: GroceryBatchCard(
                      batch: batches[i],
                      onEdit: () => onEdit(batches[i]),
                      onDelete: () => onDelete(batches[i]),
                    ),
                  ),
                  childCount: batches.length,
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ─── Header Background ────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final String productName;
  final bool isActive;

  const _HeaderBackground({
    required this.productName,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha:0.75),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.greenAccent.shade400.withValues(alpha:0.2)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? Colors.greenAccent.shade400
                            : Colors.white54,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 12,
                          color: isActive
                              ? Colors.greenAccent.shade400
                              : Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.greenAccent.shade400
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                productName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Toggle Button ─────────────────────────────────────────────────────

class _StatusToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _StatusToggleButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
        size: 18,
        color: isActive ? Colors.greenAccent.shade400 : Colors.white54,
      ),
      label: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.greenAccent.shade400 : Colors.white54,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── Sticky Tab Bar Delegate ─────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}