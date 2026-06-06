import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/lending_models.dart';

class LendingBarChart extends StatelessWidget {
  final List<LendingChartData> data;

  const LendingBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No transaction records found.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    // FIX 1: Explicitly force the ₱ symbol using compactCurrency
    final currencyFormat = NumberFormat.compactCurrency(
        locale: 'en_PH',
        symbol: '₱',
        decimalDigits: 0
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the maximum value to cap the X-axis scale
        double maxVal = 0.0;
        for (var d in data) {
          if (d.shareCapital > maxVal) maxVal = d.shareCapital;
          // FIX 2: Ensure we match our legend tracking (Total Disbursed instead of interest revenue)
          if (d.totalDisbursed > maxVal) maxVal = d.totalDisbursed;
        }

        if (maxVal <= 0) maxVal = 1000.0;
        maxVal = maxVal * 1.15; // 15% headroom

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
                        // Y-Axis: Data Labels (Periods)
                        SizedBox(
                          width: 80,
                          child: Text(
                            d.period,
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
                        // X-Axis: Bars extending horizontally
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Shareholder Capital Trend
                              _horizontalBar(d.shareCapital, maxVal, const Color(0xFFD2691E)),
                              const SizedBox(height: 4),
                              // Total Disbursed Trend
                              _horizontalBar(d.totalDisbursed, maxVal, const Color(0xFFF4A460)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // X-Axis Scale Labels
            _buildXAxisLabels(maxVal, currencyFormat),
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
        height: 10,
        width: width.clamp(0.0, constraints.maxWidth),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
        ),
      );
    });
  }

  Widget _buildXAxisLabels(double maxVal, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.only(left: 88),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('₱0', style: _axisStyle()),
          Text(format.format(maxVal * 0.5), style: _axisStyle()),
          Text(format.format(maxVal), style: _axisStyle()),
        ],
      ),
    );
  }

  TextStyle _axisStyle() => const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w500);

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Shareholder Capital', const Color(0xFFD2691E)),
        const SizedBox(width: 20),
        _legendItem('Total Disbursed', const Color(0xFFF4A460)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}