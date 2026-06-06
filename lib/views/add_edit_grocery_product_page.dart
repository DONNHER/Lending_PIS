import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../repositories/grocery_repository.dart';
import '../repositories/storage_repository.dart';
import '../viewmodels/grocery_viewmodel.dart';
import '../widgets/shared_widgets.dart';

class AddEditGroceryProductPage extends StatefulWidget {
  final GroceryWithDetails? grocery;
  
  const AddEditGroceryProductPage({super.key, this.grocery});

  @override
  State<AddEditGroceryProductPage> createState() =>
      _AddEditGroceryProductPageState();
}

class _AddEditGroceryProductPageState extends State<AddEditGroceryProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  late final _nameCtrl = TextEditingController(
      text: widget.grocery?.product.productName ?? '');
  late final _priceCtrl = TextEditingController(
      text: widget.grocery?.product.sellingPrice.toStringAsFixed(2) ?? '');
  late final _barcodeCtrl = TextEditingController(
      text: widget.grocery?.product.barcode ?? '');
  late bool _isActive = widget.grocery?.product.isActive ?? true;
  
  File? _imageFile;
  String? _existingImageUrl;
  bool _isSaving = false;
  bool _isScanning = false;

  bool get _isEdit => widget.grocery != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _existingImageUrl = widget.grocery?.product.productImage;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _existingImageUrl = null; // Clear existing URL when new image picked
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ImageSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              if (_imageFile != null || _existingImageUrl != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _imageFile = null;
                      _existingImageUrl = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Remove Image',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    setState(() => _isScanning = true);
    
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerPage(),
      ),
    );
    
    if (mounted) {
      setState(() => _isScanning = false);
      
      if (result != null && result.isNotEmpty) {
        _barcodeCtrl.text = result;
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final vm = context.read<GroceryViewModel>();
      final storageRepo = context.read<StorageRepository>();
      
      String? imageUrl = _existingImageUrl;

      // Upload new image if selected
      if (_imageFile != null) {
        try {
          final bytes = await _imageFile!.readAsBytes();
          final fileName = 'grocery_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          imageUrl = await storageRepo.uploadFile(
            fileBytes: bytes,
            fileName: fileName,
            folder: 'grocery-products',
          );
          
          debugPrint('Image uploaded successfully: $imageUrl');
        } catch (e) {
          debugPrint('Image upload failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image. Continuing without image.'),
                backgroundColor: AppTheme.warning,
              ),
            );
          }
        }
      }

      bool success;
      if (_isEdit) {
        success = await vm.updateProduct(
          grocery: widget.grocery!,
          productName: _nameCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim(),
          productImage: imageUrl,
          sellingPrice: double.tryParse(_priceCtrl.text) ?? 0,
          isActive: _isActive,
        );
      } else {
        success = await vm.createProduct(
          productName: _nameCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim(),
          productImage: imageUrl,
          sellingPrice: double.tryParse(_priceCtrl.text) ?? 0,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEdit ? 'Product updated successfully' : 'Product created successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(vm.errorMessage ?? 'Operation failed'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_isEdit ? 'Edit Grocery Product' : 'Add Grocery Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Photo upload
                _ProductImageCard(
                  imageFile: _imageFile,
                  existingImageUrl: _existingImageUrl,
                  onTap: _showImageSourceDialog,
                ),
                const SizedBox(height: 20),

                // General info
                SectionCard(
                  title: 'General Information',
                  children: [
                    GroceryFormField(
                      label: 'Product Name',
                      controller: _nameCtrl,
                      hint: 'Enter product name',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    GroceryFormField(
                      label: 'Selling Price (₱)',
                      controller: _priceCtrl,
                      hint: '0.00',
                      keyboard: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barcode
                SectionCard(
                  title: 'Barcode',
                  children: [
                    GroceryFormField(
                      label: 'Barcode',
                      controller: _barcodeCtrl,
                      hint: 'Enter barcode or scan',
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isScanning ? null : _scanBarcode,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: Text(_isScanning ? 'Scanning...' : 'Scan Barcode'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: AppTheme.primary.withValues(alpha:0.5)),
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status
                SectionCard(
                  title: 'Status',
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Availability',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark)),
                              const SizedBox(height: 2),
                              Text(
                                _isActive
                                    ? 'Product visible in PoS'
                                    : 'Inactive — hidden from PoS',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _isActive ? AppTheme.success : AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeThumbColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Save button
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Save Product',
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

// ─── Product Image Card ──────────────────────────────────────────────────────

class _ProductImageCard extends StatelessWidget {
  final File? imageFile;
  final String? existingImageUrl;
  final VoidCallback onTap;

  const _ProductImageCard({
    required this.imageFile,
    this.existingImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha:0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Photo',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha:0.3),
                ),
              ),
              child: _buildImageContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.file(
          imageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
        ),
      );
    }

    if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          existingImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined,
            color: AppTheme.primary.withValues(alpha:0.6), size: 48),
        const SizedBox(height: 12),
        Text('Tap to add product image',
            style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted.withValues(alpha:0.8))),
        const SizedBox(height: 4),
        Text('Camera or Gallery',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted.withValues(alpha:0.6))),
      ],
    );
  }
}

// ─── Image Source Option ─────────────────────────────────────────────────────

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha:0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
          ],
        ),
      ),
    );
  }
}

// ─── Barcode Scanner Page ────────────────────────────────────────────────────

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController? _controller;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      setState(() => _isScanning = false);
      
      // Vibrate to indicate successful scan
      HapticFeedback.mediumImpact();
      
      Navigator.pop(context, barcode.rawValue);
    }
  }

  void _toggleTorch() {
    _controller?.toggleTorch();
  }

  void _switchCamera() {
    _controller?.switchCamera();
  }

  void _manualEntry() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackButton(color: Colors.white),
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: const Icon(Icons.flash_on, color: Colors.white),
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black87,
            child: SafeArea(
              child: Column(
                children: [
                  const Text(
                    'Position barcode within the frame',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _manualEntry,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Enter Manually'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}