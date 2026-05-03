import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.cashier;
  int _currentStep = 0;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Handlers ──────────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AuthViewModel>();

    if (!viewModel.agreeToTerms) {
      _showSnackbar('Please agree to the Terms of Service and Privacy Policy',
          isError: true);
      return;
    }

    final success = await viewModel.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      middleName: _middleNameController.text,
      role: _selectedRole,
    );

    if (success && mounted) {
      _showSnackbar('Welcome, ${viewModel.currentUser!.fullName}!',
          isError: false);
      final dashboardRoute = viewModel.dashboardRoute;
      if (dashboardRoute != null) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(dashboardRoute, (route) => false);
      }
    } else if (mounted && viewModel.errorMessage != null) {
      _showSnackbar(viewModel.errorMessage!, isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validatePersonalInfo()) return;
    if (_currentStep == 1 && !_validateAccountInfo()) return;
    _animCtrl.forward(from: 0);
    setState(() => _currentStep++);
  }

  void _previousStep() {
    _animCtrl.forward(from: 0);
    setState(() => _currentStep--);
  }

  bool _validatePersonalInfo() {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      _showSnackbar('First name and last name are required', isError: true);
      return false;
    }
    return true;
  }

  bool _validateAccountInfo() {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackbar('Please fill in all required fields', isError: true);
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackbar('Passwords do not match', isError: true);
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showSnackbar('Password must be at least 6 characters', isError: true);
      return false;
    }
    return true;
  }

  // ─── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEE5DD)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppTheme.textDark),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PIL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Consumer<AuthViewModel>(
                builder: (context, viewModel, _) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProgressIndicator(),
                        const SizedBox(height: 28),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: _buildStepContent(viewModel),
                        ),
                        const SizedBox(height: 28),
                        _buildNavigationButtons(viewModel),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(AuthViewModel viewModel) {
    if (_currentStep == 0) return _buildPersonalInfoStep();
    if (_currentStep == 1) return _buildAccountInfoStep(viewModel);
    return _buildReviewStep(viewModel);
  }

  // ─── Progress indicator ────────────────────────────────────────────────
  Widget _buildProgressIndicator() {
    const steps = ['Personal', 'Account', 'Review'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEE5DD)),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // connector line
            final step = i ~/ 2;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                decoration: BoxDecoration(
                  color: step < _currentStep
                      ? AppTheme.success
                      : AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final step = i ~/ 2;
          final isCompleted = step < _currentStep;
          final isCurrent = step == _currentStep;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.success
                      : isCurrent
                          ? AppTheme.primary
                          : AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                steps[step],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isCurrent
                      ? AppTheme.primary
                      : AppTheme.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── Step 1: Personal info ─────────────────────────────────────────────
  Widget _buildPersonalInfoStep() {
    return _StepCard(
      icon: Icons.person_outline_rounded,
      title: 'Personal Information',
      subtitle: 'Let us know who you are',
      children: [
        AuthTextField(
          label: 'First Name *',
          hint: 'Enter your first name',
          controller: _firstNameController,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.badge_outlined,
              color: AppTheme.textMuted, size: 20),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'First name is required' : null,
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'Middle Name',
          hint: 'Enter your middle name (optional)',
          controller: _middleNameController,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.badge_outlined,
              color: AppTheme.textMuted, size: 20),
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'Last Name *',
          hint: 'Enter your last name',
          controller: _lastNameController,
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(Icons.badge_outlined,
              color: AppTheme.textMuted, size: 20),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Last name is required' : null,
        ),
      ],
    );
  }

  // ─── Step 2: Account info ──────────────────────────────────────────────
  Widget _buildAccountInfoStep(AuthViewModel viewModel) {
    return _StepCard(
      icon: Icons.manage_accounts_outlined,
      title: 'Account Setup',
      subtitle: 'Create your login credentials',
      children: [
        AuthTextField(
          label: 'Username *',
          hint: 'Choose a unique username',
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.alternate_email,
              color: AppTheme.textMuted, size: 20),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Username is required';
            if (v.trim().length < 3) return 'At least 3 characters';
            return null;
          },
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'Email Address *',
          hint: 'Enter your email address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.email_outlined,
              color: AppTheme.textMuted, size: 20),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!v.contains('@') || !v.contains('.')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'Password *',
          hint: 'Create a strong password',
          controller: _passwordController,
          obscureText: viewModel.obscurePassword,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.lock_outline,
              color: AppTheme.textMuted, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              viewModel.obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textMuted,
              size: 20,
            ),
            onPressed: viewModel.togglePasswordVisibility,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'At least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 18),
        AuthTextField(
          label: 'Confirm Password *',
          hint: 'Re-enter your password',
          controller: _confirmPasswordController,
          obscureText: viewModel.obscurePassword,
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(Icons.lock_outline,
              color: AppTheme.textMuted, size: 20),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm your password';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 22),
        // Role selector
        const Text(
          'Select Role',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 10),
        _buildRoleSelector(),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: UserRole.values.map((role) {
        final isSelected = _selectedRole == role;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: role == UserRole.values.last ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(0.2),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      _getRoleIcon(role),
                      color: isSelected ? Colors.white : AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      role.name[0].toUpperCase() + role.name.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.cashier:
        return Icons.point_of_sale_outlined;
      case UserRole.shareholder:
        return Icons.supervisor_account_outlined;
    }
  }

  // ─── Step 3: Review ────────────────────────────────────────────────────
  Widget _buildReviewStep(AuthViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepCard(
          icon: Icons.person_outlined,
          title: 'Personal Info',
          subtitle: 'Review your details',
          children: [
            _ReviewItem(
              label: 'Full Name',
              value:
                  '${_firstNameController.text} ${_lastNameController.text}',
            ),
            if (_middleNameController.text.isNotEmpty)
              _ReviewItem(
                  label: 'Middle Name',
                  value: _middleNameController.text),
          ],
        ),
        const SizedBox(height: 14),
        _StepCard(
          icon: Icons.account_circle_outlined,
          title: 'Account',
          subtitle: 'Login credentials',
          children: [
            _ReviewItem(
                label: 'Username', value: _usernameController.text),
            _ReviewItem(label: 'Email', value: _emailController.text),
            _ReviewItem(
              label: 'Role',
              value: _selectedRole.name[0].toUpperCase() +
                  _selectedRole.name.substring(1),
              valueColor: AppTheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Terms
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEE5DD)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: viewModel.agreeToTerms,
                  onChanged: (v) =>
                      viewModel.setAgreeToTerms(v ?? false),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Nav buttons ───────────────────────────────────────────────────────
  Widget _buildNavigationButtons(AuthViewModel viewModel) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: viewModel.isLoading ? null : _previousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textDark,
                side: const BorderSide(color: Color(0xFFDDD5CE)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Back',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: _currentStep < 2
              ? ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shadowColor: AppTheme.primary.withOpacity(0.4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Continue',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed:
                      viewModel.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: viewModel.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Create Account',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEE5DD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        letterSpacing: -0.2,
                      )),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF5EDE6)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReviewItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.textDark,
              )),
        ],
      ),
    );
  }
}