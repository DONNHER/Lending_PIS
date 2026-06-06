import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shareholder_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lending_models.dart';
import '../repositories/lending_repository.dart';
import '../repositories/shareholder_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final LendingRepository _lendingRepository;
  final ShareholderRepository _shareholderRepository;

  List<KpiCardData> _kpiCards = [];
  List<LendingChartData> _chartData = [];
  List<TransactionModel> _recentTransactions = [];
  String _greeting = '';
  String _currentDate = '';
  bool _isLoading = false;

  ChartFilter _selectedFilter = ChartFilter.month;

  String _searchQuery = '';
  List<ShareholderModel> _availableShareholders = [];
  List<ShareholderModel> _searchResults = [];
  RealtimeChannel? _dashboardRealtimeSubscription;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  DashboardViewModel(this._lendingRepository, this._shareholderRepository) {
    _updateGreetingAndDate();
    _initDashboard();
  }

  // Getters
  List<KpiCardData> get kpiCards => _kpiCards;
  List<LendingChartData> get chartData => _chartData;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  String get greeting => _greeting;
  String get currentDate => _currentDate;
  bool get isLoading => _isLoading;
  List<ShareholderModel> get searchResults => _searchResults;
  ChartFilter get selectedFilter => _selectedFilter;

  Future<void> _initDashboard() async {
    await _loadData(showLoading: true);
    await _loadShareholders();
    _initRealtimeListeners();
  }

  void setChartFilter(ChartFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
    _loadChartMetricsOnly();
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

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    _currentDate = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<void> _loadChartMetricsOnly() async {
    try {
      _chartData = await _lendingRepository.getLendingChartMetrics(_selectedFilter);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating chart filters: $e');
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final interestRate = await _lendingRepository.getCurrentInterestRate();
      final totalDisbursed = await _lendingRepository.getTotalDisbursedLoans();
      final totalCapital = await _lendingRepository.getTotalShareholderCapital();
      final recentTrans = await _lendingRepository.getRecentLoanTransactions(limit: 5);

      final freshChartMetrics = await _lendingRepository.getLendingChartMetrics(_selectedFilter);

      _kpiCards = [
        KpiCardData(
          label: 'Total Disbursed Loans',
          value: _currencyFormat.format(totalDisbursed),
          icon: Icons.assignment_outlined,
        ),
        KpiCardData(
          label: "Shareholder's Capital",
          value: _currencyFormat.format(totalCapital),
          icon: Icons.account_balance_wallet_outlined,
        ),
        KpiCardData(
          label: 'Current Interest Rate',
          value: '${(interestRate * 100).toStringAsFixed(1)}%',
          icon: Icons.schedule_rounded,
        ),
      ];

      _recentTransactions = recentTrans;
      _chartData = freshChartMetrics;
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (showLoading) _isLoading = false;
      notifyListeners();
    }
  }

  void _initRealtimeListeners() {
    _dashboardRealtimeSubscription = Supabase.instance.client
        .channel('public:shareholder_transactions_dashboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          callback: (payload) async => await _loadData(showLoading: false),
        )
        .subscribe();
  }

  Future<void> _loadShareholders() async {
    try {
      _availableShareholders = await _shareholderRepository.getShareholders(limit: 100);
    } catch (e) {}
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      final q = query.toLowerCase();
      _searchResults = _availableShareholders.where((s) => s.fullName.toLowerCase().contains(q)).toList();
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    await _loadData(showLoading: false);
    await _loadShareholders();
  }

  @override
  void dispose() {
    if (_dashboardRealtimeSubscription != null) Supabase.instance.client.removeChannel(_dashboardRealtimeSubscription!);
    super.dispose();
  }
}
