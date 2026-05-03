import 'package:flutter/material.dart';

class KpiCardModel {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color iconBackgroundColor;
  final bool isPositive;

  const KpiCardModel({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.iconBackgroundColor,
    required this.isPositive,
  });
}

class SaleBarModel {
  final String day;
  final double amount;
  const SaleBarModel({required this.day, required this.amount});
}

class RecentSaleModel {
  final String id;
  final String cashier;
  final double amount;
  final bool isPaid;
  final String time;
  const RecentSaleModel({
    required this.id,
    required this.cashier,
    required this.amount,
    required this.isPaid,
    required this.time,
  });
}

class LowStockItemModel {
  final String name;
  final String type;
  final int remaining;
  final int total;
  
  const LowStockItemModel({
    required this.name,
    required this.type,
    required this.remaining,
    required this.total,
  });

  bool get isOutOfStock => remaining == 0;
  double get stockRatio => total == 0 ? 0.0 : remaining / total;
}