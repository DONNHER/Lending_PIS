import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/dashboard_models.dart';

class BarChart extends StatelessWidget {
  final List<SaleBarModel> bars;
  const BarChart({super.key, required this.bars});

  @override
  Widget build(BuildContext context) {
    final maxVal = bars.map((b) => b.amount).reduce((a, b) => a > b ? a : b);
    final today = DateTime.now().weekday;
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.asMap().entries.map((entry) {
        final i = entry.key;
        final bar = entry.value;
        final isToday = days[today - 1] == bar.day;
        final heightRatio = maxVal > 0 ? bar.amount / maxVal : 0.0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isToday)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('₱${(bar.amount / 1000).toStringAsFixed(1)}k',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ),
                Flexible(
                  child: LayoutBuilder(builder: (ctx, bc) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 400 + i * 60),
                        curve: Curves.easeOutCubic,
                        height: bc.maxHeight * heightRatio,
                        decoration: BoxDecoration(
                          color: isToday ? AppTheme.primary : AppTheme.primary.withOpacity(0.25),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(bar.day, style: TextStyle(
                  fontSize: 10, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? AppTheme.primary : AppTheme.textMuted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}