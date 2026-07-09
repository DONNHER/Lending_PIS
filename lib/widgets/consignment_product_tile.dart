import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/product_model.dart';
import 'shared_widgets.dart';

class ConsignmentProductTile extends StatelessWidget {
  final ProductModel product;
  final double commissionRate;
  final double capitalPrice;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const ConsignmentProductTile({
    super.key,
    required this.product,
    required this.commissionRate,
    required this.capitalPrice,
    this.onTap,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: p.isActive
                ? AppTheme.secondary.withOpacity(0.18)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: p.isActive
                    ? AppTheme.secondary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.handshake_rounded,
                color: p.isActive ? AppTheme.secondary : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.productName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          p.isActive ? AppTheme.textDark : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.barcode,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Commission + price column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${p.sellingPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(commissionRate * 100).toStringAsFixed(0)}% comm',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                StatusBadge(active: p.isActive),
              ],
            ),
            const SizedBox(width: 10),

            // Actions — mirrors the grocery tile exactly
            Column(
              children: [
                if (onToggle != null)
                  IconButtonSmall(
                    icon: Icons.contrast_rounded,
                    color: AppTheme.secondary,
                    onTap: onToggle!,
                  ),
                if (onToggle != null) const SizedBox(height: 4),
                if (onEdit != null)
                  IconButtonSmall(
                    icon: Icons.edit_rounded,
                    color: AppTheme.primary,
                    onTap: onEdit!,
                  ),
                if (onEdit != null) const SizedBox(height: 4),
                if (onDelete != null)
                  IconButtonSmall(
                    icon: Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    onTap: onDelete!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}