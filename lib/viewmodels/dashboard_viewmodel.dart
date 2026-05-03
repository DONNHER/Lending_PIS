import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/dashboard_models.dart';

enum DashboardPeriod { today, thisWeek, thisMonth }

class DashboardViewModel extends ChangeNotifier {
  DashboardPeriod _selectedPeriod = DashboardPeriod.today;
  List<KpiCardModel> _kpiCards = [];
  List<SaleBarModel> _weeklySales = [];
  List<RecentSaleModel> _recentSales = [];
  List<LowStockItemModel> _lowStockItems = [];
  String _greeting = '';
  String _currentDate = '';
  bool _isLoading = false;

  DashboardViewModel() {
    _updateGreetingAndDate();
    _loadData();
  }

  // Getters
  DashboardPeriod get selectedPeriod => _selectedPeriod;
  List<KpiCardModel> get kpiCards => _kpiCards;
  List<SaleBarModel> get weeklySales => _weeklySales;
  List<RecentSaleModel> get recentSales => _recentSales;
  List<LowStockItemModel> get lowStockItems => _lowStockItems;
  String get greeting => _greeting;
  String get currentDate => _currentDate;
  bool get isLoading => _isLoading;

  void setPeriod(DashboardPeriod period) {
    _selectedPeriod = period;
    notifyListeners();
    _loadData();
  }

  void _updateGreetingAndDate() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour < 12) {
      _greeting = 'Good morning! 👋';
    } else if (hour < 17) {
      _greeting = 'Good afternoon! ☀️';
    } else {
      _greeting = 'Good evening! 🌙';
    }

    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    _currentDate = '${days[now.weekday-1]}, ${months[now.month-1]} ${now.day}, ${now.year}';
  }

  void _loadData() {
    _isLoading = true;
    notifyListeners();

    // Mock data - replace with repository call later
    _kpiCards = [
      KpiCardModel(label: 'Total Sales', value: '₱9,140', subtext: '+12% vs yesterday',
        icon: Icons.trending_up_rounded, iconBackgroundColor: Color(0xFF2E7D32), isPositive: true),
      KpiCardModel(label: 'Revenue', value: '₱7,320', subtext: 'Cash collected',
        icon: Icons.payments_rounded, iconBackgroundColor: AppTheme.primary, isPositive: true),
      KpiCardModel(label: 'Outstanding', value: '₱1,820', subtext: '3 unpaid credits',
        icon: Icons.credit_score_rounded, iconBackgroundColor: Color(0xFFC62828), isPositive: false),
      KpiCardModel(label: 'Transactions', value: '24', subtext: 'Sales today',
        icon: Icons.receipt_rounded, iconBackgroundColor: Color(0xFF6B3F1A), isPositive: true),
    ];

    _weeklySales = [
      SaleBarModel(day: 'Mon', amount: 1240), SaleBarModel(day: 'Tue', amount: 980),
      SaleBarModel(day: 'Wed', amount: 1560), SaleBarModel(day: 'Thu', amount: 720),
      SaleBarModel(day: 'Fri', amount: 1890), SaleBarModel(day: 'Sat', amount: 2100),
      SaleBarModel(day: 'Sun', amount: 650),
    ];

    _recentSales = [
      RecentSaleModel(id: 'SALE-2026-012', cashier: 'Goku', amount: 145.00, isPaid: true, time: '10:42 AM'),
      RecentSaleModel(id: 'SALE-2026-011', cashier: 'Sir Bo', amount: 320.00, isPaid: false, time: '10:15 AM'),
      RecentSaleModel(id: 'SALE-2026-010', cashier: 'Goku', amount: 75.00, isPaid: true, time: '9:58 AM'),
      RecentSaleModel(id: 'SALE-2026-009', cashier: 'Admin', amount: 210.00, isPaid: true, time: '9:30 AM'),
    ];

    _lowStockItems = [
      LowStockItemModel(name: 'Turon', type: 'Consignment', remaining: 5, total: 20),
      LowStockItemModel(name: 'Coke Sakto', type: 'Grocery', remaining: 0, total: 30),
      LowStockItemModel(name: 'Kalamares', type: 'Consignment', remaining: 10, total: 50),
    ];

    _isLoading = false;
    notifyListeners();
  }
}