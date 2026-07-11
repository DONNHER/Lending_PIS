import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/models/shareholder_model.dart';
import 'package:capstone_application/models/transaction_model.dart';
import 'package:capstone_application/models/dashboard_models.dart';
import 'package:capstone_application/models/lending_models.dart';

enum ChartFilter { week, month, year }

class DashboardViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  final ShareholderRepository _shareholderRepository;

  bool _isLoading = false;
  bool _isInitialized = false;
  String _greeting = 'Welcome';
  String _currentDate = '';
  ChartFilter _selectedFilter = ChartFilter.month;
  String _query = '';

  List<KpiData> _kpiCards = [];
  List<LendingChartData> _chartData = [];
  List<UserGrowthData> _userTrend = [];
  List<TransactionModel> _recentTransactions = [];
  final List<ShareholderModel> _searchResults = [];

  DashboardViewModel(
    this._lendingRepository,
    this._shareholderRepository,
  );

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String get greeting => _greeting;
  String get currentDate => _currentDate;
  ChartFilter get selectedFilter => _selectedFilter;
  List<KpiData> get kpiCards => _kpiCards;
  List<LendingChartData> get chartData => _chartData;
  List<UserGrowthData> get userTrend => _userTrend;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  List<ShareholderModel> get searchResults => _searchResults;
  String get searchQuery => _query;

  Future<void> initDashboard() async {
    if (_isInitialized) return;
    await refreshData();
    _isInitialized = true;
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentDate = DateFormat('MMMM dd, yyyy').format(DateTime.now()); 
      _greeting = _getGreeting();
      
      // Load KPIs
      final loansCount = await _lendingRepository.getLoanRequests();
      final usersCount = await _shareholderRepository.getShareholders();

      _kpiCards = [
        KpiData(label: 'Total Loans', value: '${loansCount.length}', icon: Icons.money, color: Colors.blue),
        KpiData(label: 'Total Users', value: '${usersCount.length}', icon: Icons.people, color: Colors.green),
      ];

      _chartData = [];
      _userTrend = [];
      _recentTransactions = [];

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void setChartFilter(ChartFilter filter) {
    _selectedFilter = filter;
    refreshData();
  }

  void setSearchQuery(String query) {
    _query = query;
    notifyListeners();
  }
}

class UserGrowthData {
  final String period;
  final int count;

  UserGrowthData({required this.period, required this.count});
}
