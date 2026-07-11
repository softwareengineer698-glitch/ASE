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
    // Google accounts are pre-verified — go straight to role picker
    if (!result.user!.roleSelected) {
      final chosen = await _showRolePicker();
      if (!mounted) return;
      if (chosen != null) await authProvider.updateUserRole(chosen);
    }
    if (!mounted) return;
    _navigateToDashboard();
  }

  Future<UserRole?> _showRolePicker() {
    return showModalBottomSheet<UserRole>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RolePickerSheet(
        onSelected: (role) => Navigator.of(ctx).pop(role),
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
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
                    'join_foodbridge'.tr(),
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
                      if (v.length < 6) return 'password_too_short'.tr();
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

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

// ── Role Picker Bottom Sheet ────────────────────────────────────────────────
class _RolePickerSheet extends StatelessWidget {
  final ValueChanged<UserRole> onSelected;
  const _RolePickerSheet({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(Icons.volunteer_activism_rounded,
              size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'welcome_to_foodbridge'.tr(),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'role_description'.tr(),
            style:
                TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _RoleBtn(
            icon: Icons.favorite_rounded,
            title: 'im_a_donor'.tr(),
            subtitle: 'donor_subtitle'.tr(),
            color: colorScheme.primary,
            onTap: () => onSelected(UserRole.donor),
          ),
          const SizedBox(height: 12),
          _RoleBtn(
            icon: Icons.business_rounded,
            title: 'im_an_ngo'.tr(),
            subtitle: 'ngo_subtitle'.tr(),
            color: Colors.orange,
            onTap: () => onSelected(UserRole.ngo),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RoleBtn extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleBtn({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
