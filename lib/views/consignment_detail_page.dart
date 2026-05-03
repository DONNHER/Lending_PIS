import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/consignment_daily_inventory.dart';
import '../repositories/consignment_products_repository.dart';
import '../viewmodels/consignment_detail_viewmodel.dart';
import '../viewmodels/consignment_products_viewmodels.dart';
import '../widgets/daily_inventory_card.dart';
import 'inventory_form_page.dart';
import 'inventory_detail_page.dart';

class ConsignmentDetailPage extends StatefulWidget {
  // ✅ FIX: Accept only the consignment ID, not the full object.
  //    The old page stored `widget.consignment` (a snapshot) and never
  //    re-read it, so edits/status-toggles made from this page were never
  //    reflected in the UI.  We resolve the live object from the
  //    ConsignmentProductsViewModel on every build instead.
  final int consignmentId;

  const ConsignmentDetailPage({super.key, required this.consignmentId});

  @override
  State<ConsignmentDetailPage> createState() => _ConsignmentDetailPageState();
}

class _ConsignmentDetailPageState extends State<ConsignmentDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _resolveConsignment(context.read<ConsignmentProductsViewModel>());
      if (c == null) return;

      final vm = context.read<ConsignmentDetailViewModel>();
      // ✅ FIX: seed before loadDetails so _consignment is never null
      //    during the build that follows the load.
      vm.seedConsignment(c);
      vm.loadDetails(c.consignment.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Always resolve from the live list so status/price changes are reflected.
  ConsignmentWithDetails? _resolveConsignment(ConsignmentProductsViewModel vm) {
    try {
      return vm.allConsignments.firstWhere(
        (c) => c.consignment.id == widget.consignmentId,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Navigation ──────────────────────────────────────────────────────

  void _addInventory(ConsignmentWithDetails c) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ConsignmentDetailViewModel>(),
          child: InventoryFormPage(productId: c.product.id),
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<ConsignmentDetailViewModel>().loadDetails(c.consignment.id);
    }
  }

  void _editInventory(ConsignmentWithDetails c, ConsignmentDailyInventoryModel inv) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ConsignmentDetailViewModel>(),
          child: InventoryFormPage(productId: c.product.id, inventory: inv),
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<ConsignmentDetailViewModel>().loadDetails(c.consignment.id);
    }
  }

  void _viewInventory(ConsignmentWithDetails c, ConsignmentDailyInventoryModel inv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryDetailPage(consignment: c, inventory: inv),
      ),
    );
  }

  void _deleteInventory(ConsignmentWithDetails c, ConsignmentDailyInventoryModel inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Inventory Log',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Remove this inventory entry permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<ConsignmentDetailViewModel>()
                  .deleteInventory(inv.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Live data from the list ViewModel
    final listVm = context.watch<ConsignmentProductsViewModel>();
    final c = _resolveConsignment(listVm);

    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consignment Detail')),
        body: const Center(child: Text('Consignment no longer exists.')),
      );
    }

    // Detail ViewModel for inventories
    final detailVm = context.watch<ConsignmentDetailViewModel>();
    final inventories = detailVm.inventories;
    final isActive = c.product.isActive;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Sliver App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.secondary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderBackground(
                productName: c.product.productName,
                consigneeName: c.consignee?.fullName ?? 'No consignee',
                isActive: isActive,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _StatusToggleButton(
                isActive: isActive,
                onTap: () => listVm.toggleStatus(
                  c.product.id,
                  c.product.isActive,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Stat pills ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _StatPill(
                    label: 'Sell Price',
                    value: '₱${c.product.sellingPrice.toStringAsFixed(2)}',
                    color: AppTheme.primary,
                    icon: Icons.sell_rounded,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Capital',
                    value: '₱${c.consignment.capitalPrice.toStringAsFixed(2)}',
                    color: AppTheme.secondary,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Commission',
                    value:
                        '${(c.consignment.commissionRate * 100).toStringAsFixed(0)}%',
                    color: AppTheme.warning,
                    icon: Icons.percent_rounded,
                  ),
                ],
              ),
            ),
          ),

          // ── Summary pills (from detail VM) ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _StatPill(
                    label: 'Total Sold',
                    value: '${detailVm.totalSold}',
                    color: AppTheme.success,
                    icon: Icons.shopping_bag_rounded,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Revenue',
                    value: '₱${detailVm.totalRevenue.toStringAsFixed(2)}',
                    color: AppTheme.primary,
                    icon: Icons.trending_up_rounded,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Payout',
                    value: '₱${detailVm.totalPayout.toStringAsFixed(2)}',
                    color: AppTheme.secondary,
                    icon: Icons.payments_rounded,
                  ),
                ],
              ),
            ),
          ),

          // ── Barcode + consignee chip ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_rounded,
                      size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    c.product.barcode,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.person_rounded,
                      size: 14, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      c.consignee?.fullName ?? 'No consignee',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.secondary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.secondary,
                indicatorWeight: 3,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(
                      icon: Icon(Icons.inventory_2_rounded),
                      text: 'Daily Logs'),
                  Tab(
                      icon: Icon(Icons.bar_chart_rounded),
                      text: 'Summary'),
                ],
              ),
            ),
          ),
        ],

        // ── Tab bodies ─────────────────────────────────────────────
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Daily Logs tab ─────────────────────────────────────
            _DailyLogsTab(
              c: c,
              detailVm: detailVm,
              inventories: inventories,
              onAdd: () => _addInventory(c),
              onEdit: (inv) => _editInventory(c, inv),
              onView: (inv) => _viewInventory(c, inv),
              onDelete: (inv) => _deleteInventory(c, inv),
            ),

            // ── Summary tab ────────────────────────────────────────
            _SummaryTab(c: c, vm: detailVm),
          ],
        ),
      ),
    );
  }
}

// ─── Daily Logs Tab ───────────────────────────────────────────────────────────

class _DailyLogsTab extends StatelessWidget {
  final ConsignmentWithDetails c;
  final ConsignmentDetailViewModel detailVm;
  final List<ConsignmentDailyInventoryModel> inventories;
  final VoidCallback onAdd;
  final void Function(ConsignmentDailyInventoryModel) onEdit;
  final void Function(ConsignmentDailyInventoryModel) onView;
  final void Function(ConsignmentDailyInventoryModel) onDelete;

  const _DailyLogsTab({
    required this.c,
    required this.detailVm,
    required this.inventories,
    required this.onAdd,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (detailVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (detailVm.state == DetailState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(detailVm.errorMessage ?? 'Error',
                style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => detailVm.loadDetails(c.consignment.id),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${inventories.length} log${inventories.length == 1 ? '' : 's'} · ${detailVm.totalSold} sold',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                _AddButton(label: 'Add Log', onTap: onAdd),
              ],
            ),
          ),
        ),
        inventories.isEmpty
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(message: 'No inventory logs yet. Add one!'),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: DailyInventoryCard(
                      inventory: inventories[i],
                      product: c.product,
                      consignment: c.consignment,
                      onTap: () => onView(inventories[i]),
                      onEdit: () => onEdit(inventories[i]),
                      onDelete: () => onDelete(inventories[i]),
                    ),
                  ),
                  childCount: inventories.length,
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ─── Summary Tab ─────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final ConsignmentWithDetails c;
  final ConsignmentDetailViewModel vm;

  const _SummaryTab({required this.c, required this.vm});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _SummaryRow(
          label: 'Total Received', value: '${vm.totalReceived} units'),
      _SummaryRow(label: 'Total Sold', value: '${vm.totalSold} units'),
      _SummaryRow(label: 'Total Returned', value: '${vm.totalReturned} units'),
      _SummaryRow(
          label: 'Gross Revenue',
          value: '₱${vm.totalRevenue.toStringAsFixed(2)}'),
      _SummaryRow(
          label: 'Commission (${(c.consignment.commissionRate * 100).toStringAsFixed(0)}%)',
          value: '₱${vm.totalCommission.toStringAsFixed(2)}',
          highlight: AppTheme.warning),
      _SummaryRow(
          label: 'Net Payout',
          value: '₱${vm.totalPayout.toStringAsFixed(2)}',
          highlight: AppTheme.success,
          bold: true),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppTheme.secondary.withOpacity(0.15)),
          ),
          child: Column(
            children: rows
                .map((r) => _buildRow(r, rows.last == r))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_SummaryRow r, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: AppTheme.secondary.withOpacity(0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(r.label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight:
                    r.bold ? FontWeight.w700 : FontWeight.w500,
              )),
          Text(r.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    r.bold ? FontWeight.w800 : FontWeight.w600,
                color: r.highlight ?? AppTheme.textDark,
              )),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;
  final Color? highlight;
  final bool bold;
  const _SummaryRow(
      {required this.label,
      required this.value,
      this.highlight,
      this.bold = false});
}

// ─── Header Background ────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final String productName;
  final String consigneeName;
  final bool isActive;

  const _HeaderBackground({
    required this.productName,
    required this.consigneeName,
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
            AppTheme.secondary,
            AppTheme.secondary.withOpacity(0.72),
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
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.greenAccent.shade400.withOpacity(0.2)
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
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.handshake_rounded,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 5),
                  Text(
                    consigneeName,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                ],
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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
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

// ─── Add Button ───────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Sticky Tab Bar Delegate ──────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppTheme.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => tabBar != old.tabBar;
}