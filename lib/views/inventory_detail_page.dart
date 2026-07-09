import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/consignment_daily_inventory.dart';
import '../repositories/consignment_products_repository.dart';

class InventoryDetailPage extends StatelessWidget {
  final ConsignmentWithDetails consignment;
  final ConsignmentDailyInventoryModel inventory;

  const InventoryDetailPage({
    super.key,
    required this.consignment,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    final inv = inventory;
    final p = consignment.product;
    final c = consignment.consignment;
    final revenue = inv.quantitySold * p.sellingPrice;
    final commission = revenue * c.commissionRate;
    final payout = revenue - commission;
    final soldRatio = inv.quantityReceived == 0 ? 0.0 : inv.quantitySold / inv.quantityReceived;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Inventory Detail')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product identity
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.secondary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.fastfood_rounded, color: AppTheme.secondary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                          Text(inv.id, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'monospace')),
                          Text(consignment.consignee?.fullName ?? '—', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _sectionTitle('Quantity Breakdown'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _bigStat('Received', '${inv.quantityReceived}', Icons.inbox_rounded, AppTheme.primary),
                        const SizedBox(width: 10),
                        _bigStat('Sold', '${inv.quantitySold}', Icons.sell_rounded, AppTheme.success),
                        const SizedBox(width: 10),
                        _bigStat('Returned', '${inv.quantityRemaining}', Icons.keyboard_return_rounded, AppTheme.textMuted),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: soldRatio, minHeight: 10,
                        backgroundColor: AppTheme.success.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation(soldRatio >= 0.9 ? AppTheme.success : AppTheme.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _sectionTitle('Financial Summary'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _financeRow('Total Revenue', '₱${revenue.toStringAsFixed(2)}', AppTheme.success, '${inv.quantitySold} × ₱${p.sellingPrice.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _financeRow('Canteen Commission', '₱${commission.toStringAsFixed(2)}', AppTheme.primary, '${(c.commissionRate * 100).toStringAsFixed(0)}% of revenue'),
                    const Divider(height: 20),
                    _financeRow('Payout to Consignee', '₱${payout.toStringAsFixed(2)}', AppTheme.secondary, 'Revenue − Commission', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark));

  Widget _bigStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _financeRow(String label, String value, Color color, String subtitle, {bool isBold = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: isBold ? 14 : 13, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ),
        Text(value, style: TextStyle(fontSize: isBold ? 17 : 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}