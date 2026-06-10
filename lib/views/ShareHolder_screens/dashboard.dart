import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import 'dart:async';
import '../../app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/share_capital_viewmodel.dart';
import 'managements/loan_application.dart';
import 'details_page/loan_details.dart';
import 'layouts/app.dart';

class ShareCapitalScreen extends StatelessWidget {
  const ShareCapitalScreen({super.key});

  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color borderGrey = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    return Consumer<ShareCapitalViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFC06C4D)),
          );
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${viewModel.errorMessage}'),
                ElevatedButton(
                  onPressed: () => viewModel.fetchData(),
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: viewModel.fetchData,
          color: const Color(0xFFC06C4D),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, viewModel),
                const SizedBox(height: 24),
                _buildMainCapitalCard(context, viewModel),
                
                // --- ADS CAROUSEL SECTION ---
                const SizedBox(height: 32),
                const _AdsCarousel(),
                const SizedBox(height: 32),
                // ----------------------------

                _buildHistorySection(context, viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ShareCapitalViewModel viewModel) {
    final hour = DateTime.now().hour;
    String timeGreeting = 'Good morning, ';
    if (hour >= 12 && hour < 17) timeGreeting = 'Good afternoon, ';
    if (hour >= 17) timeGreeting = 'Good evening, ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(timeGreeting, style: const TextStyle(fontSize: 14, color: textGrey)),
        Text(
          viewModel.shareholderFirstName, 
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildMainCapitalCard(BuildContext context, ShareCapitalViewModel viewModel) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('MMM dd, yyyy');

    final activeLoan = viewModel.activeLoan;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text('TOTAL SHARE CAPITAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textGrey)),
          const SizedBox(height: 8),
          Text(
            '${currencyFormat.format(viewModel.totalCapital)} PHP', 
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textDark),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeLoan != null ? 'OUTSTANDING BALANCE' : 'ACTIVE LOAN DUE DATE', 
                    style: const TextStyle(fontSize: 10, color: textGrey)
                  ),
                  const SizedBox(height: 6),
                  Text(
                    activeLoan != null 
                        ? '${currencyFormat.format(activeLoan.remainingBalance)} PHP'
                        : 'No Active Loan',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  if (activeLoan != null && activeLoan.nextRepaymentDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Next Due: ${dateFormat.format(activeLoan.nextRepaymentDate!)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFC06C4D), fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCardButton(
                    label: 'Apply Loan',
                    icon: Icons.assignment_outlined,
                    bgColor: const Color(0xFFC06C4D),
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddLoanPage()));
                    },
                  ),
                  if (activeLoan != null) ...[
                    const SizedBox(height: 8),
                    _buildCardButton(
                      label: 'View Details',
                      icon: Icons.visibility_outlined,
                      bgColor: const Color(0xFFF3F4F6),
                      textColor: const Color(0xFF32211A),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => ActiveLoanDetailsScreen(loanId: activeLoan.id)
                          )
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, ShareCapitalViewModel viewModel) {
    final currencyFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('MM/dd/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            TextButton(
              onPressed: () {
                final appLayout = AppLayout.of(context);
                if (appLayout != null) {
                  appLayout.selectedIndex = 1; // 1 is the index for Transactions
                }
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFFC06C4D),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildTableHeader(),
              if (viewModel.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No transactions found.', style: TextStyle(color: textGrey))),
                )
              else
                ...viewModel.transactions.map((tx) {
                  final isWithdrawal = tx.type.toLowerCase().contains('withdrawal');
                  return _buildTransactionRow(
                      dateFormat.format(tx.date),
                      tx.type,
                      '${isWithdrawal ? "-" : "+"}${currencyFormat.format(tx.amount)}',
                      tx.status,
                      !isWithdrawal);
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFC06C4D),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('Date',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(
              flex: 3,
              child: Text('Description',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text('Amount',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text('Status',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(String date, String desc, String amount, String status, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: borderGrey)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(date, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          Expanded(flex: 3, child: Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
          Expanded(
              flex: 2,
              child: Text(amount,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? Colors.green : Colors.red))),
          Expanded(flex: 2, child: Text(status, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
        ],
      ),
    );
  }

  Widget _buildCardButton({required String label, IconData? icon, required Color bgColor, required Color textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: textColor), const SizedBox(width: 8)],
            Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _AdsCarousel extends StatefulWidget {
  const _AdsCarousel();

  @override
  State<_AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<_AdsCarousel> {
  // Simulating infinite scroll with a large virtual count
  static const int _virtualCount = 10000;
  late final PageController _pageController;
  int _realIndex = 0;
  Timer? _timer;

  final List<Map<String, String>> _ads = [
    {
      'title': 'New Savings Plan',
      'desc': 'Secure your future with our improved interest rates.',
      'color': '0xFFE8F5E9',
      'icon': 'savings'
    },
    {
      'title': 'Grocery Discounts',
      'desc': 'Members get an extra 10% off at our grocery store.',
      'color': '0xFFFFF3E0',
      'icon': 'shopping'
    },
    {
      'title': 'Educational Loan',
      'desc': 'Apply now for your children\'s tuition with flexible terms.',
      'color': '0xFFE3F2FD',
      'icon': 'school'
    },
    {
      'title': 'Health Coverage',
      'desc': 'Ask about our medical assistance and health benefits.',
      'color': '0xFFF3E5F5',
      'icon': 'health'
    },
    {
      'title': 'Community Update',
      'desc': 'Join our upcoming community development workshop.',
      'color': '0xFFFBE9E7',
      'icon': 'people'
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set initial page to the middle of the virtual count for infinite effect
    _realIndex = (_virtualCount ~/ 2) - ((_virtualCount ~/ 2) % _ads.length);
    _pageController = PageController(initialPage: _realIndex);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                _realIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final ad = _ads[index % _ads.length];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Color(int.parse(ad['color']!)),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -15,
                        bottom: -15,
                        child: Icon(
                          _getIcon(ad['icon']!),
                          size: 100,
                          color: Colors.black.withOpacity(0.04),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC06C4D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'MEMBER INFO',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    ad['title']!,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ad['desc']!,
                                    style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.6), height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(_getIcon(ad['icon']!), size: 48, color: const Color(0xFFC06C4D).withOpacity(0.8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_ads.length, (index) {
            final isSelected = _realIndex % _ads.length == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isSelected ? 24 : 6,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC06C4D) : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'savings': return Icons.trending_up_rounded;
      case 'shopping': return Icons.shopping_cart_outlined;
      case 'school': return Icons.school_outlined;
      case 'health': return Icons.health_and_safety_outlined;
      case 'people': return Icons.group_outlined;
      default: return Icons.info_outline;
    }
  }
}
