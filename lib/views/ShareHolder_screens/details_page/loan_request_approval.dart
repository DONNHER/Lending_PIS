import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/models/shareholder_model.dart';
import 'package:capstone_application/repositories/lending_repository.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/auth_repository.dart';
import 'package:capstone_application/models/lending_models.dart';
import 'package:capstone_application/viewmodels/notification_viewmodel.dart';
import 'package:capstone_application/viewmodels/navigation_viewmodel.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';

class LoanRequestDetailsScreen extends StatefulWidget {
  final String loanRequestId;

  const LoanRequestDetailsScreen({super.key, required this.loanRequestId});

  @override
  State<LoanRequestDetailsScreen> createState() => _LoanRequestDetailsScreenState();
}

class _LoanRequestDetailsScreenState extends State<LoanRequestDetailsScreen> {
  // Creamy / Warm App Theme Colors
  static const Color primaryCream = Color(0xFF8D6E63);
  static const Color accentCream = Color(0xFFBCAAA4);
  static const Color accentRed = Color(0xFFD32F2F);
  static const Color bgLight = Color(0xFFFDF8F5);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF8D8580);

  final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
  late Future<Map<String, dynamic>> _loanDataFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loanDataFuture = _fetchFullLoanData();
  }

  Future<String?> _resolveComakerShareholderId(
      ShareholderRepository shareholderRepo,
      AuthRepository authRepo,
      ) async {
    try {
      final authVm = context.read<AuthViewModel>();
      final currentUser = authVm.currentUser;

      if (currentUser != null) {
        // 1. If shareholder object and its ID are directly available on the current/impersonated user model
        if (currentUser.shareholder?.id != null && currentUser.shareholder!.id.isNotEmpty) {
          return currentUser.shareholder!.id;
        }

        // 2. Use email from current user, fetch target user via AuthRepository, then link to shareholder
        if (currentUser.email != null && currentUser.email!.isNotEmpty) {
          final targetUserModel = await authRepo.getUserByEmail(
              currentUser.email!);

          if (targetUserModel?.shareholder?.id != null &&
              targetUserModel!.shareholder!.id.isNotEmpty) {
            return targetUserModel.shareholder!.id;
          }
        }

        // 3. Fallback to matching by user ID on shareholder repository
        if (currentUser.id.isNotEmpty) {
          final shareholderById = await shareholderRepo.getShareholderById(currentUser.id);
          if (shareholderById != null && shareholderById.id.isNotEmpty) {
            return shareholderById.id;
          }
        }
      }
    } catch (_) {}

    // Fallback to NotificationViewModel shareholderId if available
    final notificationVm = context.read<NotificationViewModel>();
    if (notificationVm.shareholderId != null && notificationVm.shareholderId!.isNotEmpty) {
      return notificationVm.shareholderId;
    }

    return null;
  }

  Future<void> _submitDecision(ComakerStatus status) async {
    if (_isSubmitting) return;

    final lendingRepo = context.read<LendingRepository>();
    final shareholderRepo = context.read<ShareholderRepository>();
    final authRepo = context.read<AuthRepository>();

    setState(() => _isSubmitting = true);

    try {
      final resolvedShareholderId = await _resolveComakerShareholderId(shareholderRepo, authRepo);

      if (resolvedShareholderId == null || resolvedShareholderId.isEmpty) {
        throw Exception('Shareholder profile could not be resolved for the impersonated user.');
      }

      await lendingRepo.setComakerDecision(
        loanRequestId: widget.loanRequestId,
        comakerShareholderId: resolvedShareholderId,
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
            backgroundColor: status == ComakerStatus.rejected ? accentRed : primaryCream,
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

  void _handleBackAction(BuildContext context) {
    final navViewModel = context.read<NavigationViewModel>();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      navViewModel.clearLoanReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loanDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgLight,
            body: const Center(child: CircularProgressIndicator(color: primaryCream)),
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildCreamyHeader(context, loan),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildBorrowerCard(borrower, loan)),
                                    const SizedBox(width: 20),
                                    Expanded(child: _buildLoanSummaryCard(loan)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildPurposeCard(loan),
                                const SizedBox(height: 20),
                                _buildComakersCard(loan),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: _buildBottomActionButtons(context, loan),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreamyHeader(BuildContext context, dynamic loan) {
    final double principal = loan?.requestedAmount ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 32, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6D4C41),
            Color(0xFF8D6E63),
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
                onPressed: () => _handleBackAction(context),
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
    Color color = const Color(0xFFFFA726);
    IconData iconData = Icons.hourglass_bottom;

    if (loan is LoanRequestModel) {
      switch (loan.status) {
        case LoanStatus.approved:
          label = "Approved";
          color = const Color(0xFF4CAF50);
          iconData = Icons.check_circle;
          break;
        case LoanStatus.released:
        case LoanStatus.active:
          label = "Live / Released";
          color = primaryCream;
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
          color = const Color(0xFFFFA726);
          iconData = Icons.hourglass_bottom;
          break;
      }
    }

    return Chip(
      avatar: Icon(iconData, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      backgroundColor: color.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildBorrowerCard(ShareholderModel? borrower, dynamic loan) {
    final name = borrower?.fullName ?? loan.shareholderName;
    final shareholderIdFormatted = loan.shareholderId.length > 8 ? loan.shareholderId.substring(0, 8) : loan.shareholderId;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryCream),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEFEBE9),
                radius: 28,
                child: Icon(Icons.person, color: primaryCream, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Shareholder", style: TextStyle(color: textGrey, fontSize: 14)),
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
        Icon(icon, size: 20, color: textGrey),
        const SizedBox(width: 12),
        Text("$label:", style: const TextStyle(color: textGrey, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  Widget _buildLoanSummaryCard(dynamic loan) {
    final double principal = loan.requestedAmount;
    final int duration = loan.tenureMonths;
    final double interestTotal = principal * (loan.interestRate / 100);
    final double totalDue = principal + interestTotal;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryCream),
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
        border: Border.all(color: Colors.brown.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: textGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryCream)),
        ],
      ),
    );
  }

  Widget _buildPurposeCard(dynamic loan) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryCream),
          ),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgLight,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.brown.shade100),
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

  Widget _buildComakersCard(dynamic loan) {
    final Map<String, dynamic> decisions = loan.comakerDecisionsMap ?? {};

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryCream),
          ),
          const Divider(height: 24),
          if (decisions.isEmpty)
            const Text("No co-makers assigned.", style: TextStyle(color: textGrey))
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
              Color statusColor = Colors.orange.shade700;
              IconData statusIcon = Icons.hourglass_bottom;

              if (status == ComakerStatus.approved) {
                statusText = "Approved";
                statusColor = Colors.green.shade700;
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
                      child: Icon(Icons.person, size: 18, color: textGrey),
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

  Widget _buildBottomActionButtons(BuildContext context, dynamic loan) {
    if (loan == null) return const SizedBox.shrink();

    if (_isSubmitting) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: cardColor,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: const SafeArea(
          child: SizedBox(
            height: 54,
            child: Center(
              child: CircularProgressIndicator(color: primaryCream),
            ),
          ),
        ),
      );
    }

    final authVm = context.read<AuthViewModel>();
    final currentUser = authVm.currentUser;
    final targetEmail = currentUser?.email;

    if (loan.shareholderId == currentUser?.shareholder?.id) {
      return const SizedBox.shrink();
    }

    final decisions = loan.comakerDecisionsMap ?? {};

    // Check decisions map against current target user's ID or Email mapping
    dynamic decisionVal;
    if (currentUser?.shareholder?.id != null) {
      decisionVal = decisions[currentUser!.shareholder!.id];
    }
    if (decisionVal == null && targetEmail != null) {
      for (var entry in decisions.entries) {
        if (entry.key.contains(targetEmail)) {
          decisionVal = entry.value;
          break;
        }
      }
    }

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
          color: cardColor,
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
                color: textGrey,
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
        color: cardColor,
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
                    backgroundColor: primaryCream,
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