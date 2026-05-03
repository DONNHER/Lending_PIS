import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/grocery_batch_model.dart';
import 'shared_widgets.dart';

class GroceryBatchCard extends StatelessWidget {
  final GroceryBatchModel batch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GroceryBatchCard({
    super.key,
    required this.batch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = batch.originalQuantity == 0
        ? 0.0
        : batch.remainingQuantity / batch.originalQuantity;
    final statusColor = batch.remainingQuantity == 0
        ? AppTheme.error
        : batch.isExpired
            ? AppTheme.error
            : batch.isExpiringSoon
                ? AppTheme.warning
                : ratio < 0.3
                    ? AppTheme.warning
                    : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(batch.id,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.secondary)),
              ),
              const Spacer(),
              if (batch.remainingQuantity == 0)
                MiniChip(label: 'No Stock', color: AppTheme.error)
              else if (batch.isExpired)
                MiniChip(label: 'Expired', color: AppTheme.error)
              else if (batch.isExpiringSoon)
                MiniChip(label: 'Expiring Soon', color: AppTheme.warning)
              else if (ratio < 0.3)
                MiniChip(label: 'Low Stock', color: AppTheme.warning),
              const SizedBox(width: 8),
              IconButtonSmall(
                  icon: Icons.edit_rounded,
                  color: AppTheme.primary,
                  onTap: onEdit),
              const SizedBox(width: 4),
              IconButtonSmall(
                  icon: Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  onTap: onDelete),
            ],
          ),
          const SizedBox(height: 6),
          // Dates
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text('Purchased: ${formatDate(batch.purchaseDate)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(width: 12),
              const Icon(Icons.event_rounded,
                  size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text('Expires: ${formatDate(batch.expirationDate)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          // Stat row
          Row(
            children: [
              Expanded(
                  child: MiniStat(
                      label: 'Cost Price',
                      value: '₱${batch.capitalPrice.toStringAsFixed(2)}')),
              const SizedBox(width: 8),
              Expanded(
                  child: MiniStat(
                      label: 'Original Qty',
                      value: '${batch.originalQuantity}')),
              const SizedBox(width: 8),
              Expanded(
                  child: MiniStat(
                      label: 'Remaining',
                      value: '${batch.remainingQuantity}',
                      valueColor: statusColor)),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${batch.remainingQuantity}/${batch.originalQuantity}'
                ' (${(ratio * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: statusColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}