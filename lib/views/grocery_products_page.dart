import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/grocery_repository.dart';
import '../viewmodels/grocery_viewmodel.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/grocery_list_tile.dart';
import 'add_edit_grocery_product_page.dart';
import 'grocery_product_detail_page.dart';

class GroceryProductsPage extends StatefulWidget {
  const GroceryProductsPage({super.key});

  @override
  State<GroceryProductsPage> createState() => _GroceryProductsPageState();
}

class _GroceryProductsPageState extends State<GroceryProductsPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroceryViewModel>().loadGroceries();
    });
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<GroceryViewModel>(),
          child: const AddEditGroceryProductPage(),
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<GroceryViewModel>().loadGroceries();
    }
  }

  Future<void> _openEdit(GroceryWithDetails g) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<GroceryViewModel>(),
          child: AddEditGroceryProductPage(grocery: g),
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<GroceryViewModel>().loadGroceries();
    }
  }

  void _openDetail(GroceryWithDetails g) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<GroceryViewModel>(),
          // ✅ FIX: pass only the ID so the detail page always reads
          //    the live object from the ViewModel instead of a stale snapshot.
          child: GroceryProductDetailPage(groceryId: g.grocery.id),
        ),
      ),
    );
  }

  void _toggleStatus(GroceryWithDetails g) {
    context.read<GroceryViewModel>().toggleProductStatus(g);
  }

  void _delete(GroceryWithDetails g) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            Text('Remove "${g.product.productName}" from grocery products?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await context.read<GroceryViewModel>().deleteProduct(g);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${g.product.productName} deleted.'),
                  backgroundColor: AppTheme.error,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroceryViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && vm.allGroceries.isEmpty) {
          return const Scaffold(
            backgroundColor: AppTheme.surface,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.state == GroceryState.error && vm.allGroceries.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(vm.errorMessage ?? 'Error',
                      style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => vm.loadGroceries(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final list = vm.groceries;
        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                GroceryHeader(
                  title: 'Grocery Products',
                  searchCtrl: _search,
                  hint: 'Search grocery...',
                  onSearchChanged: () => vm.searchGroceries(_search.text),
                  onAdd: _openAdd,
                  addLabel: 'Add Grocery',
                ),
                GroceryFilterBar(
                  options: const ['All', 'Active', 'Inactive'],
                  selected: vm.filter,
                  onSelect: (v) => vm.setFilter(v),
                ),
                Expanded(
                  child: list.isEmpty
                      ? const EmptyState(
                          message: 'No grocery products found.')
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => GroceryListTile(
                            grocery: list[i],
                            totalStock: vm.getTotalStock(list[i]),
                            onTap: () => _openDetail(list[i]),
                            onEdit: () => _openEdit(list[i]),
                            onToggle: () => _toggleStatus(list[i]),
                            onDelete: () => _delete(list[i]),
                          ),
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
            label: const Text('Add Grocery',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}