import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/viewmodels/lending_viewmodel/shareholders_viewmodel.dart';

class AddShareholderPage extends StatefulWidget {
  const AddShareholderPage({super.key});

  @override
  State<AddShareholderPage> createState() => _AddShareholderPageState();
}

class _AddShareholderPageState extends State<AddShareholderPage> {
  // Theme Palette
  static const Color darkBrown = Color(0xFF3A2318);
  static const Color terracotta = Color(0xFFC06C3E);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color borderLine = Color(0xFFE5E7EB);
  static const Color textGrey = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _capitalController = TextEditingController(text: "1000.00");
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isActive = true;
  String _selectedRole = "Member";

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _capitalController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<ShareholderViewModel>();
    
    final data = {
      'full_name': '${_firstNameController.text} ${_lastNameController.text}',
      'email': _emailController.text,
      'phone_number': _phoneController.text,
      'address': _addressController.text,
      'investment_capital': double.tryParse(_capitalController.text) ?? 0.0,
      'username': _usernameController.text,
      'role': _selectedRole,
      'is_active': isActive,
      'credit_score': 500,
    };

    final success = await viewModel.addShareholder(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shareholder account created successfully")),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? "Failed to create account")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Shareholder", 
                style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Lending System > New Account", 
                style: TextStyle(color: textGrey, fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: terracotta),
              child: const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 800;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: isMobile 
                ? Column(
                    children: [
                      _buildPersonalInfoSection(),
                      const SizedBox(height: 20),
                      _buildFinancialSection(),
                      const SizedBox(height: 20),
                      _buildCredentialsSection(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildPersonalInfoSection()),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4, 
                        child: Column(
                          children: [
                            _buildFinancialSection(),
                            const SizedBox(height: 24),
                            _buildCredentialsSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSectionCard(
      title: "Personal Information",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField("First Name", _firstNameController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField("Last Name", _lastNameController)),
            ],
          ),
          _buildTextField("Email Address", _emailController),
          _buildTextField("Phone Number", _phoneController, hint: "09XXXXXXXXX"),
          _buildTextField("Residential Address", _addressController),
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    return _buildSectionCard(
      title: "Initial Share Capital",
      child: Column(
        children: [
          _buildTextField("Initial Capital", _capitalController, prefix: "₱", hint: "0.00", subText: "Min. ₱ 1,000.00"),
          _buildTextField("Membership Fee", TextEditingController(text: "200.00"), prefix: "₱", isReadOnly: true, subText: "(Fixed)"),
        ],
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return _buildSectionCard(
      title: "Account Credentials",
      child: Column(
        children: [
          _buildTextField("Username", _usernameController),
          _buildTextField("Temporary Password", _passwordController, isPassword: true),
          _buildDropdownField("Role Assignment"),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Status: Active", style: TextStyle(fontWeight: FontWeight.w500, color: darkBrown)),
              Switch(
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
                activeThumbColor: terracotta,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkBrown)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? prefix, String? hint, String? subText, bool isPassword = false, bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkBrown)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            readOnly: isReadOnly,
            obscureText: isPassword,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint ?? label,
              prefixText: prefix != null ? "$prefix " : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderLine)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderLine)),
              fillColor: isReadOnly ? backgroundLight : Colors.white,
              filled: true,
            ),
            validator: (val) {
              if (!isReadOnly && (val == null || val.isEmpty)) return "Required";
              return null;
            },
          ),
          if (subText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(subText, style: const TextStyle(color: textGrey, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkBrown)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          style: const TextStyle(fontSize: 14, color: darkBrown),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderLine)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderLine)),
          ),
          items: const [
            DropdownMenuItem(value: "Admin", child: Text("Admin")),
            DropdownMenuItem(value: "Member", child: Text("Member")),
          ],
          onChanged: (val) => setState(() => _selectedRole = val!),
        ),
      ],
    );
  }
}
