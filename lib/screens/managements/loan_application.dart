import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/viewmodels/lending_viewmodel/loan_requests_viewmodel.dart';
import '/viewmodels/lending_viewmodel/shareholders_viewmodel.dart'; // Added this
import '/models/lending_models/shareholder.dart'; // Use the robust model
import 'package:intl/intl.dart';

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color accentPeach = Color(0xFFF5E6DA);
  static const Color textGrey = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: "2000.00");
  final _interestController = TextEditingController(text: "3.0");
  final _coMakerController = TextEditingController();
  
  // Use ShareholderModel instead of Customer
  ShareholderModel? _selectedShareholder;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 180)); 

  @override
  void dispose() {
    _amountController.dispose();
    _interestController.dispose();
    _coMakerController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: terracotta,
              onPrimary: Colors.white,
              onSurface: darkBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  void _submitApplication() async {
    if (_selectedShareholder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a borrower")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<LoanRequestViewModel>(); // Pointing to correct VM
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final interest = double.tryParse(_interestController.text) ?? 0.0;

    final success = await viewModel.applyLoan({
      'shareholder_id': _selectedShareholder!.id,
      'amount': amount,
      'interest_rate': interest,
      'due_date': _dueDate.toIso8601String(),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'co_maker_name': _coMakerController.text,
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Loan application submitted successfully"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Shareholders for the dropdown, Transactions for the submission
    final shareholderVM = context.watch<ShareholderViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: '₱');
    final dateFormat = DateFormat('MMMM dd, yyyy');

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double interest = double.tryParse(_interestController.text) ?? 0.0;
    double totalToPay = amount + (amount * (interest / 100));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("New Loan Application", 
          style: TextStyle(color: darkBrown, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isNarrow = constraints.maxWidth < 450;
          final double hPadding = constraints.maxWidth * 0.06;

          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Lending Details",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBrown)),
                        const SizedBox(height: 8),
                        const Text("Select a shareholder and provide loan details below.",
                            style: TextStyle(color: textGrey, fontSize: 13)),
                        const SizedBox(height: 32),
                        
                        _buildStepTag("Step 1", "Select Shareholder (Borrower)"),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ShareholderModel>(
                              isExpanded: true,
                              hint: const Text("Choose a Shareholder"),
                              value: _selectedShareholder,
                              items: shareholderVM.shareholders.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text("${s.fullName} (Bal: ₱${s.totalInvestment.toStringAsFixed(0)})"),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedShareholder = val),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildStepTag("Step 2", "Loan Amount & Interest Rate"),
                        if (isNarrow) ...[
                          _buildInputField("Principal Amount", _amountController, prefix: "₱"),
                          const SizedBox(height: 16),
                          _buildInputField("Interest (%)", _interestController, suffix: "%"),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(flex: 2, child: _buildInputField("Principal Amount", _amountController, prefix: "₱")),
                              const SizedBox(width: 16),
                              Expanded(flex: 1, child: _buildInputField("Interest (%)", _interestController, suffix: "%")),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        _buildStepTag("Step 3", "Security & Repayment"),
                        _buildInputField("Co-maker Name", _coMakerController, hint: "Enter Co-maker full name"),
                        const SizedBox(height: 16),
                        _buildDueDateTile(dateFormat),
                      ],
                    ),
                  ),
                  _buildSummarySection(currencyFormat, totalToPay, hPadding),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildDueDateTile(DateFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Due Date", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkBrown)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDueDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(format.format(_dueDate), style: const TextStyle(fontSize: 15)),
                const Icon(Icons.calendar_today, size: 18, color: terracotta),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTag(String step, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: accentPeach, borderRadius: BorderRadius.circular(4)),
          child: Text(step, style: const TextStyle(color: terracotta, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkBrown)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {String? prefix, String? suffix, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkBrown)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix != null ? "$prefix " : null,
            suffixText: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
          ),
          validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildSummarySection(NumberFormat format, double total, double hPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Colors.grey.withAlpha(25), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Loan Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown)),
          const SizedBox(height: 20),
          _summaryRow("Principal", format.format(double.tryParse(_amountController.text) ?? 0)),
          _summaryRow("Interest Rate", "${_interestController.text}%"),
          _summaryRow("Terms", "${_dueDate.difference(DateTime.now()).inDays ~/ 30} Months"),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Repayment", style: TextStyle(color: textGrey, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(format.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: terracotta)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submitApplication,
              style: ElevatedButton.styleFrom(backgroundColor: terracotta, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("Submit Loan Application", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: textGrey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkBrown)),
        ],
      ),
    );
  }
}