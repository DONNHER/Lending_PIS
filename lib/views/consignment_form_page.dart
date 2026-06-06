import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/consignee_model.dart';
import '../viewmodels/consignment_products_viewmodels.dart';

class ConsignmentFormPage extends StatefulWidget {
  const ConsignmentFormPage({super.key});

  @override
  State<ConsignmentFormPage> createState() => _ConsignmentFormPageState();
}

class _ConsignmentFormPageState extends State<ConsignmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Text controllers
  final _productNameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _capitalPriceCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();

  // Image
  File? _productImage;

  // Consignee selection
  ConsigneeModel? _selectedConsignee;

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _barcodeCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _capitalPriceCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  // ─── Pick Product Image ───────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null && mounted) {
        setState(() => _productImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ─── Generate Barcode ─────────────────────────────────────────────────

  void _generateBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.substring(timestamp.length - 8));
    final barcode = '480$random';
    setState(() => _barcodeCtrl.text = barcode);
  }

  // ─── Save ─────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedConsignee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a consignee'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final vm = context.read<ConsignmentProductsViewModel>();

    // Read image bytes if an image was picked
    List<int>? imageBytes;
    String? imageFileName;

    if (_productImage != null) {
      imageBytes = await _productImage!.readAsBytes();
      imageFileName = _productImage!.path.split('/').last;
    }

    final success = await vm.createConsignment(
      productName: _productNameCtrl.text.trim(),
      barcode: _barcodeCtrl.text.trim(),
      imageBytes: imageBytes, // Raw bytes for upload
      imageFileName: imageFileName, // Filename for storage
      sellingPrice: double.tryParse(_sellingPriceCtrl.text) ?? 0,
      consigneeId: _selectedConsignee!.id,
      commissionRate: (double.tryParse(_commissionCtrl.text) ?? 0) / 100,
      capitalPrice: double.tryParse(_capitalPriceCtrl.text) ?? 0,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Failed to create consignment'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Add Consignment')),
      body: SafeArea(
        child: Consumer<ConsignmentProductsViewModel>(
          builder: (context, vm, _) {
            if (!vm.isDropdownDataLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Product Image ────────────────────────────────
                    _buildImageUpload(),
                    const SizedBox(height: 20),

                    // ── Product Info Section ─────────────────────────
                    _sectionLabel('Product Information', AppTheme.primary),
                    const SizedBox(height: 12),

                    _buildTextField(
                      label: 'Product Name *',
                      controller: _productNameCtrl,
                      hint: 'Enter product name',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // ── Barcode with generator ───────────────────────
                    _sectionLabel('Barcode', AppTheme.primary),
                    const SizedBox(height: 8),
                    _buildTextField(
                      label: 'Barcode',
                      controller: _barcodeCtrl,
                      hint: 'Enter or generate barcode',
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _generateBarcode,
                      icon: const Icon(
                        Icons.generating_tokens_rounded,
                        size: 18,
                      ),
                      label: const Text('Generate Barcode'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: AppTheme.primary.withValues(alpha:0.4),
                        ),
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Pricing Section ──────────────────────────────
                    _sectionLabel('Pricing Details', AppTheme.primary),
                    const SizedBox(height: 12),

                    _buildTextField(
                      label: 'Selling Price (₱) *',
                      controller: _sellingPriceCtrl,
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      label: 'Capital Price (₱) *',
                      controller: _capitalPriceCtrl,
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      label: 'Commission Rate (%) *',
                      controller: _commissionCtrl,
                      hint: 'e.g., 20',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final rate = double.tryParse(v);
                        if (rate == null || rate < 0 || rate > 100) {
                          return 'Enter 0-100';
                        }
                        return null;
                      },
                    ),

                    // ── Price Preview ──────────────────────────────
                    if (_sellingPriceCtrl.text.isNotEmpty &&
                        _capitalPriceCtrl.text.isNotEmpty &&
                        _commissionCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildPricePreview(),
                    ],

                    const SizedBox(height: 20),

                    // ── Consignee Section ────────────────────────────
                    _sectionLabel('Consignee', AppTheme.secondary),
                    const SizedBox(height: 12),
                    _buildConsigneeDropdown(vm.consignees),
                    if (_selectedConsignee != null) ...[
                      const SizedBox(height: 10),
                      _buildConsigneeInfo(),
                    ],

                    const SizedBox(height: 32),

                    // ── Save Button ────────────────────────────────
                    ElevatedButton(
                      onPressed: vm.isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Create Consignment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Image Upload Widget ──────────────────────────────────────────────

  Widget _buildImageUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha:0.2)),
        ),
        child: _productImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_productImage!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _productImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: AppTheme.primary.withValues(alpha:0.5),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to upload product image',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Consignee Dropdown ──────────────────────────────────────────────

  Widget _buildConsigneeDropdown(List<ConsigneeModel> consignees) {
    if (consignees.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha:0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.textMuted, size: 18),
            SizedBox(width: 8),
            Text(
              'No consignees available. Add consignees first.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondary.withValues(alpha:0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ConsigneeModel>(
          value: _selectedConsignee,
          hint: const Text(
            'Select consignee',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          isExpanded: true,
          items: consignees.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: AppTheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.fullName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${c.phone} · ${c.address}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedConsignee = v),
        ),
      ),
    );
  }

  Widget _buildConsigneeInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 14, color: AppTheme.secondary),
          const SizedBox(width: 6),
          Text(
            _selectedConsignee!.phone,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.location_on_outlined,
            size: 14,
            color: AppTheme.secondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _selectedConsignee!.address,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Price Preview ─────────────────────────────────────────────────

  Widget _buildPricePreview() {
    final sellPrice = double.tryParse(_sellingPriceCtrl.text) ?? 0;
    final capitalPrice = double.tryParse(_capitalPriceCtrl.text) ?? 0;
    final commissionRate = double.tryParse(_commissionCtrl.text) ?? 0;
    final commission = sellPrice * (commissionRate / 100);
    final profit = sellPrice - capitalPrice - commission;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondary.withValues(alpha:0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calculate_rounded,
                size: 18,
                color: AppTheme.secondary,
              ),
              SizedBox(width: 8),
              Text(
                'Price Breakdown',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _previewRow(
            'Selling Price',
            '₱${sellPrice.toStringAsFixed(2)}',
            AppTheme.primary,
          ),
          const SizedBox(height: 6),
          _previewRow(
            'Capital Price',
            '-₱${capitalPrice.toStringAsFixed(2)}',
            AppTheme.error,
          ),
          const SizedBox(height: 6),
          _previewRow(
            'Commission ($commissionRate%)',
            '-₱${commission.toStringAsFixed(2)}',
            AppTheme.warning,
          ),
          const Divider(height: 16),
          _previewRow(
            'Net Profit',
            '₱${profit.toStringAsFixed(2)}',
            profit >= 0 ? AppTheme.success : AppTheme.error,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _previewRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Reusable Widgets ──────────────────────────────────────────────

  Widget _sectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
