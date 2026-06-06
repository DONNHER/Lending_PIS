import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/dashboard_models.dart';

class RecentSalesList extends StatelessWidget {
  final List<RecentSaleModel> recentSales;
  final VoidCallback? onSeeAll;
  const RecentSalesList({super.key, required this.recentSales, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Text('Recent Sales',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark))),
            if (onSeeAll != null)
              TextButton(onPressed: onSeeAll, style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary, padding: EdgeInsets.zero,
                minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('See all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 12),
          ...recentSales.map((sale) => _RecentSaleTile(sale: sale)),
        ],
      ),
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  final RecentSaleModel sale;
  const _RecentSaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.receipt_rounded, color: AppTheme.primary, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sale.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          Text('${sale.cashier} · ${sale.time}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₱${sale.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 2),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: sale.isPaid ? AppTheme.success.withValues(alpha:0.1) : AppTheme.error.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20)),
            child: Text(sale.isPaid ? 'Paid' : 'Unpaid', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: sale.isPaid ? AppTheme.success : AppTheme.error))),
        ]),
      ]),
    );
  }
}