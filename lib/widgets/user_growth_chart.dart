import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';

class UserGrowthChart extends StatelessWidget {
  final List<UserTrendData> data;

  const UserGrowthChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No registration data for this period.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int maxVal = 0;
        for (var d in data) {
          if (d.count > maxVal) maxVal = d.count;
        }

        if (maxVal <= 0) maxVal = 5;
        final double scaleMax = (maxVal * 1.2).ceilToDouble();

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(right: 12),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final d = data[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            d.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _horizontalBar(d.count.toDouble(), scaleMax, const Color(0xFF6366F1)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          d.count.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        );
      },
    );
  }

  Widget _horizontalBar(double value, double maxVal, Color color) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = (value / maxVal) * constraints.maxWidth;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        height: 14,
        width: width.clamp(0.0, constraints.maxWidth),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    });
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF6366F1), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('New Registrations', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
