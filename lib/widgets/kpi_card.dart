import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/dashboard_models.dart';

class KpiCard extends StatelessWidget {
  final KpiCardModel data;
  const KpiCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: data.iconBackgroundColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.iconBackgroundColor, size: 18),
            ),
            const Spacer(),
            Icon(data.isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: data.isPositive ? AppTheme.success : AppTheme.error, size: 14),
          ]),
          const SizedBox(height: 8),
          Text(data.value, style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(data.label, style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(data.subtext, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
            fontSize: 10, color: data.isPositive ? AppTheme.success : AppTheme.error)),
        ],
      ),
    );
  }
}