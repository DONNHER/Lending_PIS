import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/grocery_batch_model.dart';
import '../widgets/shared_widgets.dart';

class AddEditGroceryBatchPage extends StatefulWidget {
  final String productName;
  final GroceryBatchModel? batch;
  
  const AddEditGroceryBatchPage({
    super.key,
    required this.productName,
    this.batch,
  });

  @override
  State<AddEditGroceryBatchPage> createState() =>
      _AddEditGroceryBatchPageState();
}

class _AddEditGroceryBatchPageState extends State<AddEditGroceryBatchPage> {
  final _formKey = GlobalKey<FormState>();
  late final _qtyCtrl = TextEditingController(
      text: widget.batch?.originalQuantity.toString() ?? '');
  late final _costCtrl = TextEditingController(
      text: widget.batch?.capitalPrice.toStringAsFixed(2) ?? '');
  late DateTime _purchaseDate = widget.batch?.purchaseDate ?? DateTime.now();
  late DateTime _expirationDate = widget.batch?.expirationDate ?? 
      DateTime.now().add(const Duration(days: 30));

  bool get _isEdit => widget.batch != null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be greater than 0'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_expirationDate.isBefore(_purchaseDate) || 
        _expirationDate.isAtSameMomentAs(_purchaseDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expiration date must be after purchase date'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      GroceryBatchModel(
        id: _isEdit ? widget.batch!.id : '',
        productId: _isEdit ? widget.batch!.productId : '',
        capitalPrice: cost,
        originalQuantity: qty,
        remainingQuantity: qty,
        purchaseDate: _purchaseDate,
        expirationDate: _expirationDate,
      ),
    );
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isExpiry ? _expirationDate : _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expirationDate = picked;
        } else {
          _purchaseDate = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('${_isEdit ? 'Edit' : 'Add'} Batch — ${widget.productName}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha:0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Each batch tracks a separate grocery purchase. '
                          'Stock is deducted per batch (FIFO) at point of sale.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // General Information
                SectionCard(
                  title: 'General Information',
                  children: [
                    NumberField(
                      label: 'Quantity Purchased',
                      controller: _qtyCtrl,
                      hint: 'Enter quantity',
                      isInt: true,
                    ),
                    const SizedBox(height: 14),
                    NumberField(
                      label: 'Cost Price (₱)',
                      controller: _costCtrl,
                      hint: '0.00',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dates
                SectionCard(
                  title: 'Dates',
                  children: [
                    DateTile(
                      label: 'Purchase Date',
                      date: _purchaseDate,
                      onTap: () => _pickDate(isExpiry: false),
                    ),
                    const SizedBox(height: 12),
                    DateTile(
                      label: 'Expiration Date',
                      date: _expirationDate,
                      onTap: () => _pickDate(isExpiry: true),
                    ),
                    if (!_isEdit) 
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Default expiration is 30 days from today',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),

                // Save button
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isEdit ? 'Save Batch' : 'Add Batch',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Cancel button
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: AppTheme.primary.withValues(alpha:0.4)),
                    foregroundColor: AppTheme.textMuted,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}