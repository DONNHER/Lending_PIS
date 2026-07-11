import 'package:flutter/material.dart';
import 'package:capstone_application/repositories/shareholder_repository.dart';
import 'package:capstone_application/repositories/transaction_repository.dart';
import 'package:capstone_application/models/transaction_model.dart';
import 'package:capstone_application/models/shareholder_model.dart';

class AddShareCapitalViewModel extends ChangeNotifier {
  final ShareholderRepository shareholderRepo;
  final TransactionRepository transactionRepo;
  final ShareholderModel shareholder;

  final TextEditingController amountController = TextEditingController();
  final String _selectedPaymentMethod = 'Cash';
  bool _isLoading = false;

  AddShareCapitalViewModel({
    required this.shareholderRepo,
    required this.transactionRepo,
    required this.shareholder,
  });

  bool get isLoading => _isLoading;
  String get selectedPaymentMethod => _selectedPaymentMethod;

  void updateUI() {
    notifyListeners();
  }

  Future<TransactionModel?> executeInvestment() async {
    final double? amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) return null;

    _isLoading = true;
    notifyListeners();

    try {
      final transaction = await transactionRepo.createTransaction(
        userId: shareholder.id,
        amount: amount,
        type: 'Capital Contribution',
        status: 'Success',
        referenceId: 'CAP-${DateTime.now().millisecondsSinceEpoch}',
      );
      return transaction;
    } catch (e) {
      debugPrint('Error executing investment: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }
}
