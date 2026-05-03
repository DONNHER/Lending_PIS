import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/consignment_daily_inventory.dart';
import '../viewmodels/consignment_detail_viewmodel.dart';

class InventoryFormPage extends StatefulWidget {
  final String productId;
  final ConsignmentDailyInventoryModel? inventory;

  const InventoryFormPage({super.key, required this.productId, this.inventory});

  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _receivedCtrl;
  late final TextEditingController _soldCtrl;
  late DateTime _consignmentDate;

  bool get _isEdit => widget.inventory != null;

  int get _received => int.tryParse(_receivedCtrl.text) ?? 0;
  int get _sold => int.tryParse(_soldCtrl.text) ?? 0;
  int get _returned => (_received - _sold).clamp(0, _received);

  @override
  void initState() {
    super.initState();
    _receivedCtrl = TextEditingController(
        text: widget.inventory?.quantityReceived.toString() ?? '');
    _soldCtrl = TextEditingController(
        text: widget.inventory?.quantitySold.toString() ?? '');
    _consignmentDate =
        widget.inventory?.consignmentDate ?? DateTime.now();

    // ✅ Rebuild live preview whenever either field changes
    _receivedCtrl.addListener(() => setState(() {}));
    _soldCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    _soldCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _consignmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _consignmentDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sold > _received) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sold cannot exceed received'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final vm = context.read<ConsignmentDetailViewModel>();
    final bool success;

    if (_isEdit) {
      success = await vm.updateInventory(
        inventoryId: widget.inventory!.id,
        consignmentDate: _consignmentDate,
        quantityReceived: _received,
        quantitySold: _sold,
      );
    } else {
      success = await vm.addInventory(
        consignmentDate: _consignmentDate,
        quantityReceived: _received,
        quantitySold: _sold,
      );
    }

    if (mounted && success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final soldRatio = _received == 0 ? 0.0 : (_sold / _received).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Inventory Log' : 'Add Inventory Log'),
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Date picker ─────────────────────────────────────
                _FieldLabel(label: 'Consignment Date'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.secondary.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_consignmentDate.year}-'
                            '${_consignmentDate.month.toString().padLeft(2, '0')}-'
                            '${_consignmentDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded,
                            color: AppTheme.secondary, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Quantity received ────────────────────────────────
                _FieldLabel(label: 'Quantity Received'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _receivedCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    hintText: 'Enter quantity received',
                    prefixIcon: const Icon(Icons.inbox_rounded,
                        color: AppTheme.primary, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.secondary.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.secondary.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Quantity sold ────────────────────────────────────
                _FieldLabel(label: 'Quantity Sold'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _soldCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    hintText: 'Enter quantity sold',
                    prefixIcon: const Icon(Icons.sell_rounded,
                        color: AppTheme.success, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.secondary.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.secondary.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.secondary),
                    ),
                  ),
                ),

                // ── Live preview card ────────────────────────────────
                if (_received > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.secondary.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _PreviewStat(
                              label: 'Received',
                              value: '$_received',
                              color: AppTheme.primary,
                              icon: Icons.inbox_rounded,
                            ),
                            const SizedBox(width: 8),
                            _PreviewStat(
                              label: 'Sold',
                              value: '$_sold',
                              color: AppTheme.success,
                              icon: Icons.sell_rounded,
                            ),
                            const SizedBox(width: 8),
                            _PreviewStat(
                              label: 'Returned',
                              value: '$_returned',
                              color: AppTheme.textMuted,
                              icon: Icons.keyboard_return_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: soldRatio,
                            minHeight: 8,
                            backgroundColor:
                                AppTheme.success.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation(
                              soldRatio >= 0.9
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(soldRatio * 100).toStringAsFixed(0)}% sold',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Save button ──────────────────────────────────────
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _isEdit ? 'Save Changes' : 'Save Inventory',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _PreviewStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}