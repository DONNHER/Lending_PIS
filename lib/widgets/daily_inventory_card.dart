import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/consignment_daily_inventory.dart';
import '../models/consignment_model.dart';
import '../models/product_model.dart';

class DailyInventoryCard extends StatelessWidget {
  final ConsignmentDailyInventoryModel inventory;
  final ProductModel product;
  final ConsignmentModel consignment;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DailyInventoryCard({
    super.key,
    required this.inventory,
    required this.product,
    required this.consignment,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final inv = inventory;
    final revenue = inv.quantitySold * product.sellingPrice;
    final commission = revenue * consignment.commissionRate;
    final payout = revenue - commission;
    final soldRatio = inv.quantityReceived == 0 ? 0.0 : inv.quantitySold / inv.quantityReceived;
    final barColor = soldRatio >= 0.9 ? AppTheme.success : soldRatio >= 0.5 ? AppTheme.warning : AppTheme.error;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.secondary.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(_fmt(inv.consignmentDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                const Spacer(),
                if (onEdit != null) ...[
                  GestureDetector(onTap: onEdit, child: const Icon(Icons.edit_rounded, color: AppTheme.secondary, size: 18)),
                  const SizedBox(width: 10),
                ],
                if (onDelete != null)
                  GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _stat('Received', '${inv.quantityReceived}')),
                Expanded(child: _stat('Sold', '${inv.quantitySold}', AppTheme.success)),
                Expanded(child: _stat('Returned', '${inv.quantityReceived - inv.quantitySold}', AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${inv.quantitySold}/${inv.quantityReceived} sold (${(soldRatio * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: soldRatio, minHeight: 7,
                backgroundColor: barColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: _finance('Revenue', '₱${revenue.toStringAsFixed(2)}', AppTheme.success)),
                  _vDivider(),
                  Expanded(child: _finance('Commission', '₱${commission.toStringAsFixed(2)}', AppTheme.primary)),
                  _vDivider(),
                  Expanded(child: _finance('Payout', '₱${payout.toStringAsFixed(2)}', AppTheme.secondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _stat(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color ?? AppTheme.textDark)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _finance(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: AppTheme.primary.withOpacity(0.1));
}