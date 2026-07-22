import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../viewmodels/add_shareholder_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../widgets/auth_text_field.dart';
import 'address_selector_page.dart';

class AddShareholderPage extends StatefulWidget {
  const AddShareholderPage({super.key});

  @override
  State<AddShareholderPage> createState() => _AddShareholderPageState();
}

class _AddShareholderPageState extends State<AddShareholderPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shareCapitalController = TextEditingController(); // Added controller for share capital

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _shareCapitalController.dispose(); // Dispose share capital controller
    super.dispose();
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const AddressSelectorPage()),
    );
    if (result != null) {
      setState(() {
        _addressController.text = result;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address')),
      );
      return;
    }

    final viewModel = context.read<AddShareholderViewModel>();
    final newUserId = await viewModel.registerShareholder(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      initialShare: double.tryParse(_shareCapitalController.text.trim()) ?? 0.0, // Pass initial share value here
    );

    if (newUserId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shareholder added successfully')),
      );
      
      // Update global navigation state to show the new shareholder
      final nav = context.read<NavigationViewModel>();
      nav.navigateToShareholder(newUserId);
      
      // Go back to the users page (which will now show the detail view due to the state change)
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Failed to add shareholder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF32211A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Shareholder',
          style: TextStyle(color: Color(0xFF32211A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Personal Information'),
                  const SizedBox(height: 16),
                  _buildIdUpload(context),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          label: 'First Name',
                          hint: 'Enter first name',
                          controller: _firstNameController,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AuthTextField(
                          label: 'Last Name',
                          hint: 'Enter last name',
                          controller: _lastNameController,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Phone Number',
                    hint: 'e.g. 09123456789',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Address'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectAddress,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined, size: 20, color: AppTheme.textMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _addressController.text.isEmpty ? 'Select address' : _addressController.text,
                              style: TextStyle(
                                color: _addressController.text.isEmpty ? AppTheme.textMuted : AppTheme.textDark,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Share Capital Information'), // Added section title
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Initial Share Capital',
                    hint: 'e.g. 1000.00',
                    controller: _shareCapitalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Account Credentials'),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Email Address',
                    hint: 'Enter email address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Username',
                    hint: 'Choose a unique username',
                    controller: _usernameController,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Initial Password',
                    hint: 'Min 8 characters',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (v) => v!.length < 8 ? 'Min 8 characters' : null,
                  ),
                  const SizedBox(height: 32),
                  Consumer<AddShareholderViewModel>(
                    builder: (context, viewModel, _) {
                      return ElevatedButton(
                        onPressed: viewModel.isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC06C4D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: viewModel.isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Center(child: Text('Register Shareholder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF32211A)),
    );
  }

  Widget _buildIdUpload(BuildContext context) {
    return Consumer<AddShareholderViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valid ID Image',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            if (viewModel.idImageBytes != null)
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      image: DecorationImage(
                        image: MemoryImage(viewModel.idImageBytes!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: viewModel.removeIdImage,
                      icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: viewModel.pickIdImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 32, color: Color(0xFFC06C4D)),
                      SizedBox(height: 8),
                      Text(
                        'Upload Identification Card',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC06C4D)),
                      ),
                      Text(
                        'JPG or PNG, max 5MB',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
