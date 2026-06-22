import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../viewmodels/add_shareholder_viewmodel.dart';
import 'shareholder_detail_page.dart';
import 'address_selector_page.dart';

class AddShareholderPage extends StatefulWidget {
  const AddShareholderPage({super.key});

  @override
  State<AddShareholderPage> createState() => _AddShareholderPageState();
}

class _AddShareholderPageState extends State<AddShareholderPage> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddShareholderViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 900;
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildPersonalInformationCard(context, viewModel, isWide: true),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildCapitalAndFeesCard(viewModel),
                                    const SizedBox(height: 24),
                                    _buildAccountCredentialsCard(viewModel),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildPersonalInformationCard(context, viewModel, isWide: false),
                              const SizedBox(height: 24),
                              _buildCapitalAndFeesCard(viewModel),
                              const SizedBox(height: 24),
                              _buildAccountCredentialsCard(viewModel),
                              const SizedBox(height: 24),
                            ],
                          ),
                  );
                },
              ),
            ),
            _buildBottomBar(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Shareholder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Lending System', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('>', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ),
                Text('Create New Shareholder', style: TextStyle(color: AppTheme.textMuted.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformationCard(BuildContext context, AddShareholderViewModel viewModel, {required bool isWide}) {
    return _Card(
      title: 'Personal Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'First Name',
                    hint: 'First Name',
                    controller: viewModel.firstNameController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _Field(
                    label: 'Last Name',
                    hint: 'Last Name',
                    controller: viewModel.lastNameController,
                  ),
                ),
              ],
            )
          else ...[
            _Field(
              label: 'First Name',
              hint: 'First Name',
              controller: viewModel.firstNameController,
            ),
            const SizedBox(height: 20),
            _Field(
              label: 'Last Name',
              hint: 'Last Name',
              controller: viewModel.lastNameController,
            ),
          ],
          const SizedBox(height: 20),
          _Field(
            label: 'Email Address',
            hint: 'Email Address',
            controller: viewModel.emailController,
          ),
          const SizedBox(height: 20),
          _Field(
            label: 'Phone Number',
            hint: '09XXXXXXXXX',
            controller: viewModel.phoneController,
          ),
          const SizedBox(height: 20),
          _Field(
            label: 'Residential Address',
            hint: 'Tap to select address',
            controller: viewModel.addressController,
            readOnly: true,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddressSelectorPage()),
              );
              if (result != null) {
                viewModel.addressController.text = result as String;
              }
            },
            suffixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(height: 24),
          
          const Text('ID Upload', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => viewModel.pickIdImage(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
                color: viewModel.idFileBytes != null ? Colors.grey.shade50 : Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: viewModel.idFileBytes != null
                  ? Stack(
                      children: [
                        Image.memory(viewModel.idFileBytes!, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                        Container(
                          color: Colors.black.withOpacity(0.2),
                          child: const Center(child: Icon(Icons.refresh, color: Colors.white, size: 32)),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Change ID', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        )
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: AppTheme.textMuted.withOpacity(0.5), size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'ID Upload (Click to select Government ID)',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapitalAndFeesCard(AddShareholderViewModel viewModel) {
    return _Card(
      title: 'Initial Share Capital & Fees',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: 'Initial Capital',
            hint: '1000.00',
            prefix: const Padding(
              padding: EdgeInsets.only(top: 14, left: 16),
              child: Text('₱ ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ),
            controller: viewModel.initialCapitalController,
          ),
          const SizedBox(height: 4),
          const Text('Min. ₱ 1,000.00', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 20),
          _Field(
            label: 'Membership Fee',
            hint: '200.00',
            readOnly: true,
            controller: viewModel.membershipFeeController,
            prefix: const Padding(
              padding: EdgeInsets.only(top: 14, left: 16),
              child: Text('₱ ', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ),
            fillColor: const Color(0xFFFDF8F5),
          ),
          const SizedBox(height: 4),
          const Text('(Fixed)', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAccountCredentialsCard(AddShareholderViewModel viewModel) {
    return _Card(
      title: 'Account Credentials',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            label: 'Username',
            hint: 'Username',
            controller: viewModel.usernameController,
          ),
          const SizedBox(height: 20),
          _Field(
            label: 'Temporary Password',
            hint: 'Temporary Password',
            controller: viewModel.passwordController,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Requirement: At least 8 characters, with uppercase, lowercase, number, and special character.',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AddShareholderViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(0, 0),
            ),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: viewModel.isLoading
                ? null
                : () async {
                    final success = await viewModel.createAccount();
                    if (success) {
                      if (context.mounted) {
                        final created = viewModel.createdShareholder;
                        if (created != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShareholderDetailPage(shareholderId: created.id),
                            ),
                          );
                        } else {
                          Navigator.pop(context, true);
                        }
                      }
                    } else if (viewModel.errorMessage != null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.errorMessage!), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC06C4D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              minimumSize: const Size(0, 0),
              elevation: 0,
            ),
            child: viewModel.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final Widget? prefix;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final bool readOnly;
  final bool obscureText;
  final Color? fillColor;
  final VoidCallback? onTap;

  const _Field({
    required this.label,
    required this.hint,
    this.prefix,
    this.suffixIcon,
    this.controller,
    this.readOnly = false,
    this.obscureText = false,
    this.fillColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscureText,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffixIcon,
            fillColor: fillColor ?? Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
