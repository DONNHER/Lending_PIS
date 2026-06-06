import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../models/shareholder_model.dart';
import '../repositories/shareholder_repository.dart';
import '../repositories/transaction_repository.dart';

class AddShareCapitalViewModel extends ChangeNotifier {
  final ShareholderRepository _shareholderRepo;
  final TransactionRepository _transactionRepo;
  final ShareholderModel shareholder;

  bool _isLoading = false;
  String? _errorMessage;

  final amountController = TextEditingController(text: '5,000.00');
  String selectedPaymentMethod = 'Cash';

  AddShareCapitalViewModel({
    required ShareholderRepository shareholderRepo,
    required TransactionRepository transactionRepo,
    required this.shareholder,
  })  : _shareholderRepo = shareholderRepo,
        _transactionRepo = transactionRepo;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get typedAmount => double.tryParse(amountController.text.replaceAll(',', '').replaceAll('₱', '').trim()) ?? 0.0;

  void updateUI() => notifyListeners();

  Future<bool> executeInvestment() async {
    final amount = typedAmount;
    if (amount <= 0) {
      _errorMessage = 'Please enter a valid amount';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final double newTotalCapital = shareholder.totalShareCapital + amount;
      await _shareholderRepo.updateShareCapital(shareholder.id, newTotalCapital);

      final String generatedReferenceId = 'CAP-${DateTime.now().millisecondsSinceEpoch}';
      await _transactionRepo.insertTransaction({
        'shareholder_id': shareholder.id,
        'amount': amount,
        'type': 'Capital Contribution',
        'method': selectedPaymentMethod,
        'status': 'Successful',
        'date': DateTime.now().toIso8601String(),
        'reference_id': generatedReferenceId,
      });

      // Attempt to get IP, but handle failures gracefully (e.g. on Web)
      String? deviceIp;
      try {
        final info = NetworkInfo();
        deviceIp = await info.getWifiIP();
      } catch (e) {
        debugPrint('NetworkInfo Notice: Could not retrieve IP address. This is expected on some platforms (like Web).');
      }

      await _transactionRepo.logActivity(
        action: 'CAPITAL_DEPOSIT',
        details: 'Deposited ₱${amount.toStringAsFixed(2)} share capital into the account of ${shareholder.fullName}. Ref: $generatedReferenceId',
        shareholderId: shareholder.id,
        ipAddress: deviceIp,
      );

      return true;
    } catch (e) {
      debugPrint('AddShareCapitalViewModel ERROR: $e');
      _errorMessage = e.toString();
      return false;
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
