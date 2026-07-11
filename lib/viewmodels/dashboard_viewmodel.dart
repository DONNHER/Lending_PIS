import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/models/shareholder_model.dart';
import 'package:capstone_application/models/transaction_model.dart';
import 'package:capstone_application/models/dashboard_models.dart';
import 'package:capstone_application/models/lending_models.dart';

enum ChartFilter { week, month, year }

class DashboardViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  final ShareholderRepository _shareholderRepository;
  final TransactionRepository _transactionRepository;

  bool _isLoading = false;
  bool _isChartLoading = false;
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
    this._transactionRepository,
  );

  bool get isLoading => _isLoading;
  bool get isChartLoading => _isChartLoading;
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
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      _currentDate = DateFormat('MMMM dd, yyyy').format(DateTime.now()); 
      _greeting = _getGreeting();
      
      await Future.wait([
        _loadKpis(),
        _loadChartData(),
        _loadTransactions(),
      ]);

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadKpis() async {
    final loansCount = await _lendingRepository.getLoanRequests();
    final usersCount = await _shareholderRepository.getShareholders();
    final totalDisbursed = await _lendingRepository.getTotalDisbursed();
    final interestRate = await _lendingRepository.getInterestRate();

    final currencyFormatter = NumberFormat.compactCurrency(symbol: '₱', decimalDigits: 1);

    _kpiCards = [
      KpiData(
        label: 'Disbursed', 
        value: currencyFormatter.format(totalDisbursed), 
        icon: Icons.account_balance_wallet_rounded, 
        color: Colors.orange
      ),
      KpiData(
        label: 'Loans', 
        value: '${loansCount.length}', 
        icon: Icons.assignment_rounded, 
        color: Colors.blue
      ),
      KpiData(
        label: 'Users', 
        value: '${usersCount.length}', 
        icon: Icons.people_rounded, 
        color: Colors.green
      ),
      KpiData(
        label: 'Interest', 
        value: '${(interestRate * 100).toStringAsFixed(1)}%', 
        icon: Icons.percent_rounded, 
        color: Colors.purple
      ),
    ];
  }

  Future<void> _loadChartData() async {
    _isChartLoading = true;
    notifyListeners();
    try {
      _chartData = await _lendingRepository.getMetrics(range: _selectedFilter.name);
      debugPrint('DEBUG: Dashboard loaded ${_chartData.length} chart data points');
    } catch (e) {
      debugPrint('Error loading chart data: $e');
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final all = await _transactionRepository.getTransactions();
      _recentTransactions = all.take(5).toList();
      debugPrint('DEBUG: Dashboard loaded ${_recentTransactions.length} transactions');
    } catch (e) {
      debugPrint('Error loading recent transactions: $e');
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
    _loadChartData();
  }

  void setSearchQuery(String query) async {
    _query = query;
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    try {
      final results = await _shareholderRepository.getPaginatedShareholders(
        search: query,
        perPage: 5,
      );
      _searchResults.clear();
      _searchResults.addAll(results['shareholders']);
    } catch (e) {
      debugPrint('Error searching shareholders: $e');
    }
    notifyListeners();
  }
}

class UserGrowthData {
  final String period;
  final int count;

  UserGrowthData({required this.period, required this.count});
}
