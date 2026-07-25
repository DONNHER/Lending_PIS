import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/models/shareholder_model.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/viewmodels/notification_viewmodel.dart';
import 'package:capstone_application/viewmodels/navigation_viewmodel.dart';

class LoanRequestDetailsScreen extends StatefulWidget {
  final String loanRequestId;

  const LoanRequestDetailsScreen({super.key, required this.loanRequestId});

  @override
  State<LoanRequestDetailsScreen> createState() => _LoanRequestDetailsScreenState();
}

class _LoanRequestDetailsScreenState extends State<LoanRequestDetailsScreen> {
  // Color Palette Updates
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF43A047);
  static const Color accentRed = Color(0xFFD32F2F);
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color textGrey = Color(0xFF9CA3AF);

  final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
  late Future<Map<String, dynamic>> _loanDataFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loanDataFuture = _fetchFullLoanData();
  }

  Future<void> _submitDecision(ComakerStatus status) async {
    if (_isSubmitting) return;

    final lendingRepo = context.read<LendingRepository>();
    final shareholderId = context.read<NotificationViewModel>().shareholderId;

    if (shareholderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile not found.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await lendingRepo.setComakerDecision(
        loanRequestId: widget.loanRequestId,
        comakerShareholderId: shareholderId,
        status: status,
      );

      final refreshedData = await _fetchFullLoanData();

      if (mounted) {
        setState(() {
          _loanDataFuture = Future.value(refreshedData);
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${status == ComakerStatus.rejected ? 'cancelled' : 'approved'} successfully'),
            backgroundColor: status == ComakerStatus.rejected ? accentRed : primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _fetchFullLoanData() async {
    final lendingRepo = context.read<LendingRepository>();
    final shareholderRepo = context.read<ShareholderRepository>();

    final loanRequest = await lendingRepo.getLoanRequestById(widget.loanRequestId);
    if (loanRequest == null) throw Exception("Loan request not found");

    final borrower = await shareholderRepo.getShareholderById(loanRequest.shareholderId);

    return {
      'loan': loanRequest,
      'borrower': borrower,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loanDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgLight,
            body: const Center(child: CircularProgressIndicator(color: primaryGreen)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: bgLight,
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        final dynamic loan = snapshot.data?['loan'];
        final borrower = snapshot.data?['borrower'] as ShareholderModel?;

        return Scaffold(
          backgroundColor: bgLight,
          body: Column(
            children: [
              _buildColoredHeader(loan),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Side-by-side Cards: Borrower & Loan Summary
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildBorrowerCard(borrower, loan)),
                              const SizedBox(width: 20),
                              Expanded(child: _buildLoanSummaryCard(loan)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Purpose Card
                          _buildPurposeCard(loan),
                          const SizedBox(height: 20),

                          // Co-makers Card
                          _buildComakersCard(loan),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom Actions Container
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: _buildBottomActionButtons(loan),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. Colored Header Component
  Widget _buildColoredHeader(dynamic loan) {
    final double principal = loan?.requestedAmount ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 32, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen,
            accentGreen,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.read<NavigationViewModel>().clearLoanReview(),
              ),
              const SizedBox(width: 8),
              const Text(
                "Loan Request Review",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Requested Loan Amount",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(principal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildStatusTag(loan),
        ],
      ),
    );
  }

  Widget _buildStatusTag(dynamic loan) {
    String label = "Pending Approval";
    Color color = const Color(0xFFFB8C00);
    IconData iconData = Icons.hourglass_bottom;

    if (loan is LoanRequestModel) {
      switch (loan.status) {
        case LoanStatus.approved:
          label = "Approved";
          color = Colors.green;
          iconData = Icons.check_circle;
          break;
        case LoanStatus.released:
        case LoanStatus.active:
          label = "Live / Released";
          color = primaryGreen;
          iconData = Icons.bolt;
          break;
        case LoanStatus.rejected:
          label = "Rejected";
          color = accentRed;
          iconData = Icons.cancel;
          break;
        case LoanStatus.cancelled:
          label = "Cancelled";
          color = Colors.grey;
          iconData = Icons.block;
          break;
        case LoanStatus.fullyPaid:
          label = "Fully Paid";
          color = Colors.teal;
          iconData = Icons.verified;
          break;
        case LoanStatus.overdue:
          label = "Overdue";
          color = Colors.deepOrange;
          iconData = Icons.warning;
          break;
        case LoanStatus.pending:
          label = "Pending Approval";
          color = const Color(0xFFFB8C00);
          iconData = Icons.hourglass_bottom;
          break;
      }
    }

    return Chip(
      avatar: Icon(iconData, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  // 2. Improved Borrower Card Component
  Widget _buildBorrowerCard(ShareholderModel? borrower, dynamic loan) {
    final name = borrower?.fullName ?? loan.shareholderName;
    final shareholderIdFormatted = loan.shareholderId.length > 8 ? loan.shareholderId.substring(0, 8) : loan.shareholderId;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(blurRadius: 15, color: Colors.black12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Borrower Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                radius: 28,
                child: Icon(Icons.person, color: primaryGreen, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Shareholder", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.badge, "ID", shareholderIdFormatted),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.account_balance, "Share Capital", currencyFormat.format(borrower?.shareCapital ?? 0)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, "Member Since", "Active Member"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text("$label:", style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  // 3. Better Loan Summary Grid Metrics Component
  Widget _buildLoanSummaryCard(dynamic loan) {
    final double principal = loan.requestedAmount;
    final int duration = loan.tenureMonths;
    final double interestTotal = principal * (loan.interestRate / 100);
    final double totalDue = principal + interestTotal;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(blurRadius: 15, color: Colors.black12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Loan Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const Divider(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _buildMetricTile("Principal", currencyFormat.format(principal)),
              _buildMetricTile("Interest (${loan.interestRate}%)", currencyFormat.format(interestTotal)),
              _buildMetricTile("Duration", "$duration Months"),
              _buildMetricTile("Total Due", currencyFormat.format(totalDue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryGreen)),
        ],
      ),
    );
  }

  // 4. Highlighted Purpose Container Component
  Widget _buildPurposeCard(dynamic loan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(blurRadius: 15, color: Colors.black12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Loan Purpose",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              loan.purpose,
              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Co-makers Card Component
  Widget _buildComakersCard(dynamic loan) {
    final Map<String, dynamic> decisions = loan.comakerDecisionsMap ?? {};

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(blurRadius: 15, color: Colors.black12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Co-makers",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          const Divider(height: 24),
          if (decisions.isEmpty)
            const Text("No co-makers assigned.", style: TextStyle(color: Colors.grey))
          else
            ...decisions.entries.map((entry) {
              final String comakerId = entry.key;
              final dynamic decisionVal = entry.value;

              ComakerStatus status = ComakerStatus.pending;
              if (decisionVal is ComakerStatus) {
                status = decisionVal;
              } else if (decisionVal is String) {
                status = ComakerStatus.values.firstWhere(
                      (e) => e.name.toLowerCase() == decisionVal.toLowerCase(),
                  orElse: () => ComakerStatus.pending,
                );
              }

              String statusText = "Pending";
              Color statusColor = Colors.orange;
              IconData statusIcon = Icons.hourglass_bottom;

              if (status == ComakerStatus.approved) {
                statusText = "Approved";
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == ComakerStatus.rejected) {
                statusText = "Rejected";
                statusColor = accentRed;
                statusIcon = Icons.cancel;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: bgLight,
                      radius: 18,
                      child: Icon(Icons.person, size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "ID: ${comakerId.length > 8 ? comakerId.substring(0, 8) : comakerId}",
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const Spacer(),
                    Chip(
                      avatar: Icon(statusIcon, color: statusColor, size: 16),
                      label: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      backgroundColor: statusColor.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // 6. Action Buttons Component
  Widget _buildBottomActionButtons(dynamic loan) {
    if (loan == null) return const SizedBox.shrink();

    if (_isSubmitting) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: const SafeArea(
          child: SizedBox(
            height: 54,
            child: Center(
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          ),
        ),
      );
    }

    final shareholderId = context.read<NotificationViewModel>().shareholderId;

    if (loan.shareholderId == shareholderId) {
      return const SizedBox.shrink();
    }

    final decisions = loan.comakerDecisionsMap ?? {};
    final decisionVal = decisions[shareholderId ?? ''];

    ComakerStatus? status;
    if (decisionVal is ComakerStatus) {
      status = decisionVal;
    } else if (decisionVal is String) {
      status = ComakerStatus.values.firstWhere(
            (e) => e.name.toLowerCase() == decisionVal.toLowerCase(),
        orElse: () => ComakerStatus.pending,
      );
    }

    if (status != null && status != ComakerStatus.pending) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "You already ${status == ComakerStatus.approved ? 'approved' : 'rejected'} this request.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 15,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => _submitDecision(ComakerStatus.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentRed,
                    side: const BorderSide(color: accentRed, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Reject Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _submitDecision(ComakerStatus.approved),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Approve Loan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}