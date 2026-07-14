import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/localized_error_text.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'email_otp_screen.dart';
import 'sign_in_screen.dart';
import '../main/main_wrapper.dart';

/// Registration screen — collects name, email, password.
/// Sends a verification email after account creation, then
/// goes to EmailOtpScreen where the user verifies before role selection.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 1. Create the Firebase account
      final user = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: UserRole.donor,
        userName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user == null || authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(localizedErrorText(
              authProvider.error, 'registration_failed')),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // 2. Send verification email via Firebase Auth
      await authProvider.sendEmailVerification();

      if (!mounted) return;

      // 3. Go to email OTP / verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: _emailController.text.trim(),
            userName: _nameController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _signUpWithGoogle() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (result == null || result.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localizedErrorText(
          authProvider.error,
          'auth_error_google_sign_in_failed',
        )),
        backgroundColor: Colors.red,
      ));
      return;
    }
    // Go directly to dashboard — no role picker needed
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapper()),
      (_) => false,
    );
  }

  Widget _buildPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) strength++;

    if (password.isEmpty) return const SizedBox.shrink();

    final labels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [Colors.red, Colors.orange, Colors.yellow.shade700, Colors.lightGreen, Colors.green];
    final label = labels[strength - 1];
    final color = colors[strength - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: strength / 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: [
          _reqChip('8+ chars', password.length >= 8),
          _reqChip('A-Z', password.contains(RegExp(r'[A-Z]'))),
          _reqChip('a-z', password.contains(RegExp(r'[a-z]'))),
          _reqChip('0-9', password.contains(RegExp(r'[0-9]'))),
          _reqChip('!@#', password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))),
        ]),
      ],
    );
  }

  Widget _reqChip(String label, bool met) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(met ? Icons.check_circle : Icons.cancel,
          size: 13, color: met ? Colors.green : Colors.grey),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: met ? Colors.green : Colors.grey)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                FadeInDown(
                  child: Icon(Icons.volunteer_activism_rounded,
                      size: 72, color: colorScheme.primary),
                ),
                const SizedBox(height: 20),

                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'create_account'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),

                FadeInDown(
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    'join_CareCircle'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Full name
                SlideInLeft(
                  duration: const Duration(milliseconds: 500),
                  child: CustomTextField(
                    controller: _nameController,
                    label: 'full_name'.tr(),
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'name_required'.tr()
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                SlideInLeft(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 60),
                  child: CustomTextField(
                    controller: _emailController,
                    label: 'email'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'email_required'.tr();
                      }
                      if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(v.trim())) {
                        return 'invalid_email'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Phone (optional)
                SlideInLeft(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 90),
                  child: CustomTextField(
                    controller: _phoneController,
                    label: 'phone_number'.tr(),
                    hint: 'enter_phone_hint'.tr(),
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d\s\+\-\(\)]')),
                    ],
                    // Optional — no validator required
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                SlideInLeft(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 120),
                  child: CustomTextField(
                    controller: _passwordController,
                    label: 'password'.tr(),
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'password_required'.tr();
                      }
                      if (v.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!v.contains(RegExp(r'[A-Z]'))) {
                        return 'Password must contain an uppercase letter';
                      }
                      if (!v.contains(RegExp(r'[a-z]'))) {
                        return 'Password must contain a lowercase letter';
                      }
                      if (!v.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain a number';
                      }
                      if (!v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) {
                        return 'Password must contain a special character';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Password strength indicator
                _buildPasswordStrength(_passwordController.text),
                const SizedBox(height: 8),

                // Confirm password
                SlideInLeft(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 180),
                  child: CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'confirm_password'.tr(),
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (v) => v != _passwordController.text
                        ? 'passwords_do_not_match'.tr()
                        : null,
                  ),
                ),
                const SizedBox(height: 32),

                FadeInUp(
                  delay: const Duration(milliseconds: 250),
                  child: CustomButton(
                    text: _isLoading
                        ? 'sending_otp'.tr()
                        : 'send_otp'.tr(),
                    onPressed: _isLoading ? null : _signUp,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signUpWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: Text('sign_up_with_google'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('already_have_account'.tr(),
                        style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignInScreen()),
                      ),
                      child: Text('sign_in'.tr(),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
