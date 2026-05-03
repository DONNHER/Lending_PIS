import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String currentDate;
  final DashboardPeriod selectedPeriod;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  const DashboardHeader({
    super.key, required this.greeting, required this.currentDate,
    required this.selectedPeriod, required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greeting, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          const Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(currentDate, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _periodChip('Today', DashboardPeriod.today),
            _periodChip('Week', DashboardPeriod.thisWeek),
            _periodChip('Month', DashboardPeriod.thisMonth),
          ]),
        ),
      ]),
    );
  }

  Widget _periodChip(String label, DashboardPeriod period) {
    final selected = period == selectedPeriod;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppTheme.textMuted)),
      ),
    );
  }
}