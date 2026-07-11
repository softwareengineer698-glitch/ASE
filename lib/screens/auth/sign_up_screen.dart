import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/localized_error_text.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main/main_wrapper.dart';
import 'otp_verification_screen.dart';
import 'sign_in_screen.dart';

/// Unified registration — no role selected here.
/// Role is chosen after login via the role-picker bottom sheet.
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
  bool _isSendingOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('0') && !digits.startsWith('+')) {
      return '+92${digits.substring(1)}';
    }
    if (!digits.startsWith('+')) return '+$digits';
    return digits;
  }

  void _showBypassDialog(String errorMsg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('SMS Verification Unavailable'),
        content: Text(
            'Firebase SMS Auth is not enabled in this region or project configuration:\n\n'
            '$errorMsg\n\n'
            'Would you like to complete registration directly using your Email and Password instead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _signUpDirectly();
            },
            child: const Text('Register with Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _signUpDirectly() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isSendingOtp = true);

    try {
      await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: UserRole.donor,
        userName: _nameController.text.trim(),
        phoneNumber: _normalizePhone(_phoneController.text.trim()),
      );

      if (!mounted) return;
      setState(() => _isSendingOtp = false);

      if (authProvider.isAuthenticated && authProvider.user != null) {
        final chosen = await _showRolePicker();
        if (!mounted) return;
        if (chosen != null) {
          await authProvider.updateUserRole(chosen);
        }
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapper()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              localizedErrorText(authProvider.error, 'registration_failed')),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registration error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = _normalizePhone(_phoneController.text.trim());
    setState(() => _isSendingOtp = true);

    await authProvider.sendOtp(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _isSendingOtp = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: phone,
              verificationId: verificationId,
              resendToken: resendToken,
              signUpEmail: _emailController.text.trim(),
              signUpPassword: _passwordController.text.trim(),
              signUpName: _nameController.text.trim(),
            ),
          ),
        );
      },
      onFailed: (error) {
        if (!mounted) return;
        setState(() => _isSendingOtp = false);
        _showBypassDialog(error);
      },
      onAutoVerified: (PhoneAuthCredential credential) {
        if (!mounted) return;
        setState(() => _isSendingOtp = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: phone,
              verificationId: '',
              autoVerifiedCredential: credential,
              signUpEmail: _emailController.text.trim(),
              signUpPassword: _passwordController.text.trim(),
              signUpName: _nameController.text.trim(),
            ),
          ),
        );
      },
    );
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
    if (!result.user!.roleSelected) {
      final chosen = await _showRolePicker();
      if (!mounted) return;
      if (chosen != null) await authProvider.updateUserRole(chosen);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapper()),
      (_) => false,
    );
  }

  Future<UserRole?> _showRolePicker() {
    return showModalBottomSheet<UserRole>(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // must choose a role
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RolePickerSheet(
        onSelected: (role) => Navigator.of(ctx).pop(role),
      ),
    );
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

                // Logo
                FadeInDown(
                  child: Icon(
                    Icons.volunteer_activism_rounded,
                    size: 72,
                    color: colorScheme.primary,
                  ),
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

                // Phone number (required for OTP verification)
                SlideInLeft(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 60),
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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'phone_required'.tr();
                      }
                      final normalized = _normalizePhone(v.trim());
                      if (!RegExp(r'^\+\d{10,15}$').hasMatch(normalized)) {
                        return 'invalid_phone_number'.tr();
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                SlideInLeft(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 80),
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

                // Password
                SlideInLeft(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 160),
                  child: CustomTextField(
                    controller: _passwordController,
                    label: 'password'.tr(),
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                  delay: const Duration(milliseconds: 240),
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

                Consumer<AuthProvider>(
                  builder: (context, auth, _) => FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: CustomButton(
                      text:
                          _isSendingOtp ? 'sending_otp'.tr() : 'send_otp'.tr(),
                      onPressed:
                          (auth.isLoading || _isSendingOtp) ? null : _signUp,
                      isLoading: auth.isLoading || _isSendingOtp,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _signUpWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: Text('sign_up_with_google'.tr()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      ),
                      child: Text('sign_in'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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

// ── Role Picker Bottom Sheet ─────────────────────────────────────────────────
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
            color: Colors.black.withAlpha(38),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(Icons.volunteer_activism_rounded,
              size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'How do you want to use FoodBridge?',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'You can change this later in your profile.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _RoleOption(
                  icon: Icons.volunteer_activism_rounded,
                  title: 'Donate',
                  subtitle: 'Share food & items',
                  color: colorScheme.primary,
                  onTap: () => onSelected(UserRole.donor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RoleOption(
                  icon: Icons.shopping_basket_rounded,
                  title: 'Receive',
                  subtitle: 'Find food & items',
                  color: Colors.orange,
                  onTap: () => onSelected(UserRole.ngo),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
