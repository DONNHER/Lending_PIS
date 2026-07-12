import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstone_application/app_theme.dart';
import 'package:capstone_application/viewmodels/auth_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/loan_request_viewmodel.dart';
import '../viewmodels/shareholder_viewmodel.dart';
import '../viewmodels/transaction_viewmodel.dart';
import '../viewmodels/activity_log_viewmodel.dart';
import '../viewmodels/update_interest_viewmodel.dart';
import '../viewmodels/user_management_viewmodel.dart';
import '../widgets/auth_text_field.dart';
import 'registration_page.dart';
import 'forgot_password_page.dart';
import 'mfa_page.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminLoginContent();
  }
}

class _AdminLoginContent extends StatefulWidget {
  const _AdminLoginContent();

  @override
  State<_AdminLoginContent> createState() => _AdminLoginContentState();
}

class _AdminLoginContentState extends State<_AdminLoginContent>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Pre-fill email if remembered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = context.read<AuthViewModel>();
      if (viewModel.rememberedEmail != null) {
        setState(() {
          _emailController.text = viewModel.rememberedEmail!;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Unfocus to prevent DOM sync errors on Web
    FocusScope.of(context).unfocus();

    final viewModel = context.read<AuthViewModel>();
    final success = await viewModel.login(
      _emailController.text,
      _passwordController.text,
      isAdminLogin: true,
    );

    if (success && mounted) {
      // 🚀 BOOTSTRAP SYNC: Load all management data before leaving the login page
      try {
        await Future.wait([
          context.read<DashboardViewModel>().initDashboard(),
          context.read<LoanRequestViewModel>().fetchLoanRequests(),
          context.read<ShareholderViewModel>().fetchShareholders(),
          context.read<UserManagementViewModel>().fetchUsers(),
          context.read<TransactionViewModel>().fetchTransactions(),
          context.read<ActivityLogViewModel>().fetchLogs(),
          context.read<UpdateInterestViewModel>().loadData(),
        ]);
      } catch (e) {
        debugPrint('Pre-loading warning: $e');
      }

      if (!mounted) return;

      final dashboardRoute = viewModel.dashboardRoute;
      if (dashboardRoute != null) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(dashboardRoute, (route) => false);
      }
    } else if (mounted) {
      if (viewModel.isMfaRequired) {
        final mfaEmail = viewModel.pendingMfaEmail;
        if (mfaEmail != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MfaPage(email: mfaEmail),
            ),
          );
        }
      } else if (viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(viewModel.errorMessage!)),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Consumer<AuthViewModel>(
                        builder: (context, viewModel, _) {
                          return Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),
                                _buildBranding(),
                                const SizedBox(height: 44),
                                const Text(
                                  'Admin Portal',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Sign in to manage your system',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textMuted,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                AuthTextField(
                                  label: 'Admin Email',
                                  hint: 'Enter your admin email',
                                  controller: _emailController,
                                  keyboardType:
                                      TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  prefixIcon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                AuthTextField(
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  controller: _passwordController,
                                  obscureText: viewModel.obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleLogin(),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      viewModel.obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textMuted,
                                      size: 20,
                                    ),
                                    onPressed:
                                        viewModel.togglePasswordVisibility,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => viewModel.setRememberMe(!viewModel.rememberMe),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: Checkbox(
                                                value: viewModel.rememberMe,
                                                onChanged: (val) => viewModel.setRememberMe(val ?? false),
                                                activeColor: AppTheme.primary,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Remember Me', style: TextStyle(fontSize: 13, color: AppTheme.textDark)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const ForgotPasswordPage(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primary,
                                        textStyle: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        padding: EdgeInsets.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child:
                                          const Text('Forgot Password?'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                _SignInButton(
                                  isLoading: viewModel.isLoading,
                                  onPressed: _handleLogin,
                                ),
                                const SizedBox(height: 28),
                                Row(
                                  children: [
                                    const Expanded(
                                        child: Divider(
                                            color: Color(0xFFE8DDD5))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Text(
                                        'New Admin?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                        child: Divider(
                                            color: Color(0xFFE8DDD5))),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                OutlinedButton(
                                  onPressed: () {
                                    viewModel.clearError();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const RegistrationPage(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primary,
                                    side: BorderSide(
                                      color: AppTheme.primary
                                          .withOpacity(0.4),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Create an Admin Account'),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'PIL',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'PIL ADMIN',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Management Dashboard Access',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: isLoading
              ? AppTheme.primary.withOpacity(0.6)
              : AppTheme.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Synchronizing Portal...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.login_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Admin Sign In',
                      style: TextStyle(
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
