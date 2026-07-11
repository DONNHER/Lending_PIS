import 'package:flutter/material.dart';

class KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double trend;

  KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend = 0.0,
  });
}
