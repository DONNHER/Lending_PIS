import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Bottom sheet for adding or editing a consignment product
/// Used to link a product to a consignee with pricing details
class ConsignmentFormSheet extends StatefulWidget {
  final String? productName; // Pre-filled if editing
  final double? existingCommissionRate;
  final double? existingCapitalPrice;
  final String title;

  const ConsignmentFormSheet({
    super.key,
    this.productName,
    this.existingCommissionRate,
    this.existingCapitalPrice,
    required this.title,
  });

  @override
  State<ConsignmentFormSheet> createState() => _ConsignmentFormSheetState();
}

class _ConsignmentFormSheetState extends State<ConsignmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  
  // For adding new: product name is entered manually
  // For editing: product name is pre-filled and read-only
  late final _productNameCtrl = TextEditingController(
    text: widget.productName ?? '',
  );
  late final _commissionCtrl = TextEditingController(
    text: widget.existingCommissionRate != null
        ? (widget.existingCommissionRate! * 100).toStringAsFixed(0)
        : '',
  );
  late final _capitalPriceCtrl = TextEditingController(
    text: widget.existingCapitalPrice?.toStringAsFixed(2) ?? '',
  );

  bool get isEditing => widget.productName != null;

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _commissionCtrl.dispose();
    _capitalPriceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'product_name': _productNameCtrl.text.trim(),
      'commission_rate': (double.tryParse(_commissionCtrl.text) ?? 0) / 100,
      'capital_price': double.tryParse(_capitalPriceCtrl.text) ?? 0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),

            // Product name (editable only when adding new)
            _buildField(
              label: 'Product Name *',
              controller: _productNameCtrl,
              hint: 'Enter product name',
              readOnly: isEditing,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Commission rate
            _buildField(
              label: 'Commission Rate (%) *',
              controller: _commissionCtrl,
              hint: 'e.g., 20',
              keyboardType: TextInputType.number,
              suffix: '%',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final rate = double.tryParse(v);
                if (rate == null || rate < 0 || rate > 100) return 'Enter 0-100';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Capital price
            _buildField(
              label: 'Capital Price (₱) *',
              controller: _capitalPriceCtrl,
              hint: '0.00',
              keyboardType: TextInputType.number,
              prefix: '₱',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final price = double.tryParse(v);
                if (price == null || price < 0) return 'Enter valid price';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Submit button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(isEditing ? 'Save Changes' : 'Add Consignment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? prefix,
    String? suffix,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
          ),
        ),
      ],
    );
  }
}