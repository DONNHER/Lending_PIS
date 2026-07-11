import 'package:flutter/material.dart';
import '../app_theme.dart';

class ConsignmentFormSheet extends StatefulWidget {
  final String title;
  final String? productName;
  final double? existingCommissionRate;
  final double? existingCapitalPrice;

  const ConsignmentFormSheet({
    super.key,
    required this.title,
    this.productName,
    this.existingCommissionRate,
    this.existingCapitalPrice,
  });

  @override
  State<ConsignmentFormSheet> createState() => _ConsignmentFormSheetState();
}

class _ConsignmentFormSheetState extends State<ConsignmentFormSheet> {
  late final TextEditingController _commissionController;
  late final TextEditingController _capitalPriceController;

  @override
  void initState() {
    super.initState();
    _commissionController = TextEditingController(
      text: widget.existingCommissionRate?.toString() ?? '',
    );
    _capitalPriceController = TextEditingController(
      text: widget.existingCapitalPrice?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _commissionController.dispose();
    _capitalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          if (widget.productName != null) ...[
            const SizedBox(height: 16),
            Text('Product: ${widget.productName}'),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _commissionController,
            decoration: const InputDecoration(labelText: 'Commission Rate (%)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _capitalPriceController,
            decoration: const InputDecoration(labelText: 'Capital Price'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'commission_rate': double.tryParse(_commissionController.text) ?? 0.0,
                  'capital_price': double.tryParse(_capitalPriceController.text) ?? 0.0,
                });
              },
              child: const Text('Save'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
