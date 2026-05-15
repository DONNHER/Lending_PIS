import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/consignee_model.dart';
import '../viewmodels/consignee_viewmodel.dart';

class ConsigneeFormPage extends StatefulWidget {
  final ConsigneeModel? consignee;

  const ConsigneeFormPage({super.key, this.consignee});

  @override
  State<ConsigneeFormPage> createState() => _ConsigneeFormPageState();
}

class _ConsigneeFormPageState extends State<ConsigneeFormPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final _nameCtrl =
      TextEditingController(text: widget.consignee?.fullName ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.consignee?.phone ?? '');
  late final _addressCtrl =
      TextEditingController(text: widget.consignee?.address ?? '');

  File? _healthCardFile;
  File? _foodHandlerCardFile;

  bool _keepExistingHealthCard = true;
  bool _keepExistingFoodHandlerCard = true;

  // Animation controllers for card entrance
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool get _isEdit => widget.consignee != null;

  bool get _hasHealthCardImage =>
      _healthCardFile != null ||
      (_isEdit &&
          _keepExistingHealthCard &&
          widget.consignee!.healthCardUrl != null);

  bool get _hasFoodHandlerCardImage =>
      _foodHandlerCardFile != null ||
      (_isEdit &&
          _keepExistingFoodHandlerCard &&
          widget.consignee!.foodHandlerCardUrl != null);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Save ──────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<ConsigneeViewModel>();

    List<int>? healthCardBytes;
    List<int>? foodHandlerCardBytes;

    if (_healthCardFile != null) {
      healthCardBytes = await _healthCardFile!.readAsBytes();
    }
    if (_foodHandlerCardFile != null) {
      foodHandlerCardBytes = await _foodHandlerCardFile!.readAsBytes();
    }

    bool success;
    if (_isEdit) {
      success = await viewModel.updateConsignee(
        id: widget.consignee!.id,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        healthCardBytes: healthCardBytes,
        foodHandlerCardBytes: foodHandlerCardBytes,
        healthCardFileName: _healthCardFile?.path.split('/').last,
        foodHandlerCardFileName: _foodHandlerCardFile?.path.split('/').last,
      );
    } else {
      success = await viewModel.addConsignee(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        healthCardBytes: healthCardBytes,
        foodHandlerCardBytes: foodHandlerCardBytes,
        healthCardFileName: _healthCardFile?.path.split('/').last,
        foodHandlerCardFileName: _foodHandlerCardFile?.path.split('/').last,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
      } else {
        _showError(viewModel.errorMessage ?? 'Operation failed');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Image Picker ──────────────────────────────────────────────────────
  Future<void> _pickImage({
    required bool isHealthCard,
    required ImageSource source,
  }) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (picked != null && mounted) {
        setState(() {
          if (isHealthCard) {
            _healthCardFile = File(picked.path);
            _keepExistingHealthCard = false;
          } else {
            _foodHandlerCardFile = File(picked.path);
            _keepExistingFoodHandlerCard = false;
          }
        });
      }
    } catch (e) {
      if (mounted) _showError('Failed to pick image: $e');
    }
  }

  void _showImageSourceSheet({required bool isHealthCard}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(isHealthCard: isHealthCard, source: ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(isHealthCard: isHealthCard, source: ImageSource.gallery);
        },
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black12,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Color(0xFF2D2D2D)),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 14),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEdit ? 'Edit Consignee' : 'New Consignee',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isEdit
                        ? 'Update supplier information'
                        : 'Fill in the supplier details below',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8A8FA8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Info Card ───────────────────────────────────
                      _FormCard(
                        title: 'General Information',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _StyledTextField(
                            label: 'Full Name',
                            controller: _nameCtrl,
                            hint: 'Enter complete name',
                            prefixIcon: Icons.badge_outlined,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Full name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _StyledTextField(
                            label: 'Phone Number',
                            controller: _phoneCtrl,
                            hint: '+63 9XX XXX XXXX',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Phone number is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _StyledTextField(
                            label: 'Address',
                            controller: _addressCtrl,
                            hint: 'Street, Barangay, City',
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Address is required'
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Documents Card ──────────────────────────────
                      _FormCard(
                        title: 'Required Documents',
                        icon: Icons.folder_copy_outlined,
                        subtitle:
                            'Upload clear, legible photos of each document',
                        children: [
                          _DocumentUploadTile(
                            label: 'Health Card',
                            icon: Icons.health_and_safety_outlined,
                            accentColor: const Color(0xFF3B82F6),
                            imageFile: _healthCardFile,
                            existingUrl: _isEdit && _keepExistingHealthCard
                                ? widget.consignee!.healthCardUrl
                                : null,
                            hasImage: _hasHealthCardImage,
                            onUpload: () =>
                                _showImageSourceSheet(isHealthCard: true),
                            onRemove: () => setState(() {
                              _healthCardFile = null;
                              _keepExistingHealthCard = false;
                            }),
                          ),
                          const SizedBox(height: 12),
                          const _Divider(),
                          const SizedBox(height: 12),
                          _DocumentUploadTile(
                            label: 'Food Handler Card',
                            icon: Icons.restaurant_outlined,
                            accentColor: const Color(0xFF10B981),
                            imageFile: _foodHandlerCardFile,
                            existingUrl:
                                _isEdit && _keepExistingFoodHandlerCard
                                    ? widget.consignee!.foodHandlerCardUrl
                                    : null,
                            hasImage: _hasFoodHandlerCardImage,
                            onUpload: () =>
                                _showImageSourceSheet(isHealthCard: false),
                            onRemove: () => setState(() {
                              _foodHandlerCardFile = null;
                              _keepExistingFoodHandlerCard = false;
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Save Button ─────────────────────────────────
                      Consumer<ConsigneeViewModel>(
                        builder: (context, vm, _) {
                          return _SaveButton(
                            isLoading: vm.isLoading,
                            isEdit: _isEdit,
                            onPressed: _save,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget> children;

  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: const Color(0xFF1A1A2E)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF0F1F5)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFBEC3CF),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(prefixIcon, size: 18, color: const Color(0xFFBEC3CF)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Document Upload Tile ───────────────────────────────────────────────────

class _DocumentUploadTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final File? imageFile;
  final String? existingUrl;
  final bool hasImage;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _DocumentUploadTile({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.imageFile,
    required this.existingUrl,
    required this.hasImage,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            // Status chip
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: hasImage
                  ? _StatusChip(
                      key: const ValueKey('done'),
                      label: 'Uploaded',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_rounded,
                    )
                  : _StatusChip(
                      key: const ValueKey('req'),
                      label: 'Optional',
                      color: const Color(0xFF9CA3AF),
                      icon: Icons.add_photo_alternate_rounded,
                    ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Image area
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: hasImage
              ? _ImagePreview(
                  key: const ValueKey('preview'),
                  file: imageFile,
                  url: existingUrl,
                  accentColor: accentColor,
                  onReplace: onUpload,
                  onRemove: onRemove,
                )
              : _UploadDropzone(
                  key: const ValueKey('dropzone'),
                  accentColor: accentColor,
                  onTap: onUpload,
                ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDropzone extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const _UploadDropzone({super.key, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        width: double.infinity, // always fill the card width
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha:  0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_photo_alternate_outlined,
                  size: 28, color: accentColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to upload photo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Camera or gallery · JPG, PNG',
              style: TextStyle(fontSize: 11, color: Color(0xFFADB5C7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File? file;
  final String? url;
  final Color accentColor;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  const _ImagePreview({
    super.key,
    required this.file,
    required this.url,
    required this.accentColor,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Image
          SizedBox(
            height: 180,
            width: double.infinity,
            child: file != null
                ? Image.file(file!, fit: BoxFit.cover)
                : url != null
                    ? Image.network(
                        url!,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFF0F1F5),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: accentColor,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, _, __) => Container(
                          color: const Color(0xFFF0F1F5),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: Color(0xFFBEC3CF), size: 32),
                              SizedBox(height: 6),
                              Text('Failed to load',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFBEC3CF))),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),

          // Gradient overlay at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons — bottom right
          Positioned(
            bottom: 10,
            right: 10,
            child: Row(
              children: [
                _OverlayButton(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Replace',
                  onTap: onReplace,
                  color: Colors.white.withOpacity(0.15),
                ),
                const SizedBox(width: 6),
                _OverlayButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove',
                  onTap: onRemove,
                  color: Colors.red.withOpacity(0.75),
                ),
              ],
            ),
          ),

          // "Uploaded" badge — top left
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Uploaded',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _OverlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        color: Color(0xFFF0F1F5),
      );
}

// ── Image Source Bottom Sheet ──────────────────────────────────────────────

class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImageSourceSheet({
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20, top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Text(
                'Upload Document',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose how you\'d like to add the image',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Take Photo',
                      subtitle: 'Use camera',
                      color: const Color(0xFF3B82F6),
                      onTap: onCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      subtitle: 'From photos',
                      color: const Color(0xFF10B981),
                      onTap: onGallery,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Cancel
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Save Button ────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final bool isEdit;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isLoading,
    required this.isEdit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: isLoading
              ? const Color(0xFF1A1A2E).withOpacity(0.5)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1A1A2E).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEdit
                          ? Icons.save_rounded
                          : Icons.person_add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Save Changes' : 'Add Consignee',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  
}