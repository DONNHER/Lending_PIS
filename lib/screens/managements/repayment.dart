import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/loan_requests_viewmodel.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/transactions_viewmodel.dart';
import 'package:capstone_application/models/lending_models/loan_request.dart';
import 'package:intl/intl.dart';

class RepaymentScreen extends StatefulWidget {
  const RepaymentScreen({super.key});

  @override
  State<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends State<RepaymentScreen> {
  // Theme Palette matching administrative UI (Peaches & Cream)
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color borderLine = Color(0xFFE6DED8);
  static const Color textGrey = Color(0xFF6B7280);

  LoanRequestModel? _selectedLoan;
  final _amountController = TextEditingController();
  String _paymentMethod = "Cash";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Repayments usually target approved loans
      context.read<LoanRequestViewModel>().loadPendingRequests(); 
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loanVM = context.watch<LoanRequestViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: '₱');

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Loan Repayment", 
          style: TextStyle(color: darkBrown, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 800;
          final double horizontalPadding = isMobile ? 16.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: isMobile 
              ? Column(
                  children: [
                    _buildRepaymentForm(loanVM),
                    const SizedBox(height: 20),
                    _buildLoanDescriptionSidebar(currencyFormat),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildRepaymentForm(loanVM),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildLoanDescriptionSidebar(currencyFormat),
                    ),
                  ],
                ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildRepaymentForm(LoanRequestViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formLabel("Select an Active Loan"),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8), 
              border: Border.all(color: borderLine),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<LoanRequestModel>(
                isExpanded: true,
                value: _selectedLoan,
                hint: const Text("Select a Loan"),
                items: viewModel.pendingRequests.map((loan) {
                  return DropdownMenuItem(
                    value: loan,
                    child: Text("${loan.borrower?.fullName ?? 'Unknown'} - ID: ${loan.id}"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLoan = value;
                    if (value != null) {
                      _amountController.text = value.requestedAmount.toStringAsFixed(2);
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _formLabel("Repayment Amount"),
          _buildTextField(
            controller: _amountController,
            prefix: "₱",
            hint: "0.00"
          ),
          const SizedBox(height: 20),
          _formLabel("Payment Method"),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8), 
              border: Border.all(color: borderLine),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _paymentMethod,
                items: ["Cash", "G-Cash", "Bank Transfer"].map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildProcessingStatusBox(),
          const SizedBox(height: 12),
          const Text("Note: Payments will be deducted from the total outstanding balance.", 
            style: TextStyle(color: textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLoanDescriptionSidebar(NumberFormat currencyFormat) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkBrown,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Loan Details", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _sidebarItem("Borrower", _selectedLoan?.borrower?.fullName ?? "None"),
          _sidebarItem("Loan ID", _selectedLoan?.id?.toString() ?? "N/A"),
          _sidebarItem("Interest Rate", "${_selectedLoan?.interestRate ?? 0}%"),
          _sidebarItem("Due Date", (_selectedLoan != null && _selectedLoan!.dueDate != null) ? dateFormat.format(_selectedLoan!.dueDate!) : "N/A"),
          const Divider(color: Colors.white24, height: 32),
          _sidebarItem("Principal", currencyFormat.format(_selectedLoan?.requestedAmount ?? 0)),
          _sidebarItem("Interest Amount", currencyFormat.format((_selectedLoan?.requestedAmount ?? 0) * ((_selectedLoan?.interestRate ?? 0) / 100))),
          const Divider(color: Colors.white24, height: 32),
          _sidebarItem("Total Due", currencyFormat.format((_selectedLoan?.requestedAmount ?? 0) * (1 + (_selectedLoan?.interestRate ?? 0) / 100)), isLarge: true),
        ],
      ),
    );
  }

  Widget _buildProcessingStatusBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Status Check", style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown)),
          const SizedBox(height: 4),
          Text(_selectedLoan != null ? "Ready for processing repayment." : "Please select a loan to proceed.", 
            style: const TextStyle(color: textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: borderLine)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: textGrey))),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () async {
              if (_selectedLoan != null && _selectedLoan!.id != null) {
                final txVM = context.read<TransactionsViewModel>();
                final amount = double.tryParse(_amountController.text) ?? 0.0;
                
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                final success = await txVM.recordRepayment(
                  loanId: _selectedLoan!.id!,
                  amount: amount,
                  method: _paymentMethod,
                );

                if (success && mounted) {
                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Repayment Recorded Successfully"), backgroundColor: Colors.green));
                  navigator.pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: terracotta,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Execute Repayment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _formLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: darkBrown, fontSize: 13)),
  );

  Widget _buildTextField({String? prefix, String? hint, required TextEditingController controller}) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      prefixText: prefix != null ? "$prefix " : null,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderLine)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderLine)),
      fillColor: Colors.white,
      filled: true,
    ),
  );

  Widget _sidebarItem(String label, String value, {bool isLarge = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
          color: Colors.white, 
          fontSize: isLarge ? 18 : 14, 
          fontWeight: isLarge ? FontWeight.bold : FontWeight.w500
        )),
      ],
    ),
  );
}
