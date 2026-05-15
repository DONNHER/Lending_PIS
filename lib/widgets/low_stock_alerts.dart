import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/dashboard_models.dart';

class LowStockAlerts extends StatelessWidget {
  final List<LowStockItemModel> lowStockItems;
  const LowStockAlerts({super.key, required this.lowStockItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16)),
          const SizedBox(width: 8),
          const Expanded(child: Text('Low Stock Alerts',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark))),
        ]),
        const SizedBox(height: 12),
        ...lowStockItems.map((item) => _LowStockTile(item: item)),
      ]),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final LowStockItemModel item;
  const _LowStockTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isOutOfStock ? AppTheme.error 
        : item.stockRatio < 0.3 ? AppTheme.warning : AppTheme.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(item.isOutOfStock ? 'Out of stock' : '${item.remaining} left',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))),
        ]),
        const SizedBox(height: 4),
        Text(item.type, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: item.stockRatio, minHeight: 5,
            backgroundColor: color.withOpacity(0.12), valueColor: AlwaysStoppedAnimation(color))),
      ]),
    );
  }
}