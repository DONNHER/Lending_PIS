import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../repositories/grocery_repository.dart';
import 'shared_widgets.dart';

class GroceryListTile extends StatelessWidget {
  final GroceryWithDetails grocery;
  final int totalStock;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const GroceryListTile({
    super.key,
    required this.grocery,
    required this.totalStock,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = grocery.product;
    final stockColor = totalStock == 0
        ? AppTheme.error
        : totalStock <= 5
            ? AppTheme.warning
            : AppTheme.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: p.isActive ? AppTheme.surfaceCard : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_grocery_store_rounded,
                color: p.isActive ? AppTheme.primary : Colors.grey.shade400,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.productName,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.isActive
                              ? AppTheme.textDark
                              : Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text(p.barcode,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
            // Stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$totalStock',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: stockColor)),
                const Text('stock',
                    style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(width: 12),
            // Price + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₱${p.sellingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                const SizedBox(height: 3),
                StatusBadge(active: p.isActive),
              ],
            ),
            const SizedBox(width: 10),
            // Actions
            Column(
              children: [
                IconButtonSmall(
                    icon: Icons.contrast_rounded,
                    color: AppTheme.secondary,
                    onTap: onToggle),
                const SizedBox(height: 4),
                IconButtonSmall(
                    icon: Icons.edit_rounded,
                    color: AppTheme.primary,
                    onTap: onEdit),
                const SizedBox(height: 4),
                IconButtonSmall(
                    icon: Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    onTap: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}