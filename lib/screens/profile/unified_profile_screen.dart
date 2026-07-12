import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../auth/sign_in_screen.dart';

class UnifiedProfileScreen extends StatefulWidget {
  const UnifiedProfileScreen({super.key});
  @override
  State<UnifiedProfileScreen> createState() => _UnifiedProfileScreenState();
}

class _UnifiedProfileScreenState extends State<UnifiedProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orgController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  Map<String, dynamic>? _profileData;
  File? _selectedImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (doc.exists) {
        _profileData = doc.data();
      } else {
        _profileData = {
          'name': user.email.split('@')[0], 'email': user.email,
          'phone': '', 'organization': '', 'address': '', 'bio': '',
          'createdAt': DateTime.now().toIso8601String(),
        };
      }
      _populateControllers();
    } catch (e) {
      _snack('Failed to load profile: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    if (_profileData != null) {
      // Support both 'name' (profile-saved) and 'userName' (auth-created) fields
      _nameController.text = _profileData!['name'] as String? ??
          _profileData!['userName'] as String? ?? '';
      _emailController.text = _profileData!['email'] as String? ?? '';
      // Support both 'phone' and 'phoneNumber'
      _phoneController.text = _profileData!['phone'] as String? ??
          _profileData!['phoneNumber'] as String? ?? '';
      _orgController.text = _profileData!['organization'] as String? ??
          _profileData!['organizationName'] as String? ?? '';
      _addressController.text = _profileData!['address'] as String? ?? '';
      _bioController.text = _profileData!['bio'] as String? ?? '';
      _profileImageUrl = _profileData!['profileImageUrl'] as String?;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'organization': _orgController.text.trim(),
        'address': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdAt': _profileData?['createdAt'] ?? DateTime.now().toIso8601String(),
      };
      await FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .set(data, SetOptions(merge: true));
      _profileData = {...?_profileData, ...data};
      setState(() => _isEditing = false);
      _snack('Profile updated successfully!', Colors.green);
    } catch (e) {
      _snack('Failed to save: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color,
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final img = await _picker.pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 75);
      if (img == null) return;
      setState(() { _selectedImage = File(img.path); _isUploadingImage = true; });
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;
      final result = await _cloudinary.uploadDonationImage(
          file: img, donationId: 'profile_${user.uid}', index: 0);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': result.secureUrl,
        'profileImagePublicId': result.publicId,
      });
      if (mounted) {
        setState(() { _profileImageUrl = result.secureUrl; });
        _snack('Profile picture updated!', Colors.green);
      }
    } catch (e) {
      _snack('Failed to upload image: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('change_profile_picture'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          TextButton(onPressed: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              child: Text('gallery'.tr())),
          TextButton(onPressed: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              child: Text('camera'.tr())),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('confirm_logout'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('logout'.tr())),
        ],
      ),
    );
    if (ok == true) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const SignInScreen()), (_) => false);
      }
    }
  }

  String _getInitials() {
    final org = _profileData?['organization'] as String? ?? '';
    final name = _profileData?['name'] as String? ?? '';
    final src = org.isNotEmpty ? org : name;
    if (src.isEmpty) return 'U';
    final words = src.trim().split(' ');
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return src[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isLoading && _profileData == null) {
      return const Scaffold(body: Center(child: LoadingWidget()));
    }
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true)),
          if (_isEditing)
            IconButton(icon: const Icon(Icons.close),
                onPressed: () { setState(() => _isEditing = false); _populateControllers(); }),
        ],
      ),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(key: _formKey, child: Column(children: [
          _buildHeader(colorScheme),
          const SizedBox(height: 24),
          _buildForm(colorScheme),
          const SizedBox(height: 24),
          _buildSettings(colorScheme),
          const SizedBox(height: 16),
        ])),
      )),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Card(elevation: 2, child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Stack(children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!) as ImageProvider
                : (_profileImageUrl?.isNotEmpty == true)
                    ? NetworkImage(_profileImageUrl!) as ImageProvider
                    : null,
            child: (_selectedImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                ? Text(_getInitials(), style: TextStyle(fontSize: 32,
                    fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer))
                : null,
          ),
          if (_isUploadingImage)
            Positioned.fill(child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black45,
              child: const CircularProgressIndicator(color: Colors.white),
            )),
          Positioned(right: 0, top: 0,
            child: Container(
              decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: _showImageDialog,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Text(
          _profileData?['organization'] != null && (_profileData!['organization'] as String).isNotEmpty
              ? _profileData!['organization'] as String
              : _profileData?['name'] ?? 'Your Name',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(_profileData?['email'] ?? '',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            SizedBox(width: 4),
            Text('Active Member', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w500, color: Colors.green)),
          ]),
        ),
      ]),
    ));
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return Card(elevation: 2, child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Personal Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        CustomTextField(controller: _nameController, label: 'full_name'.tr(),
            hint: 'enter_full_name'.tr(), prefixIcon: Icons.person, enabled: _isEditing,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'full_name_required'.tr() : null),
        const SizedBox(height: 14),
        CustomTextField(controller: _orgController, label: 'organization_name'.tr(),
            hint: 'enter_organization_name'.tr(), prefixIcon: Icons.business,
            enabled: _isEditing),
        const SizedBox(height: 14),
        CustomTextField(controller: _emailController, label: 'email_address'.tr(),
            hint: '', prefixIcon: Icons.email, enabled: false,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        CustomTextField(controller: _phoneController, label: 'phone_number'.tr(),
            hint: 'enter_phone_number'.tr(), prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone, enabled: _isEditing,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'phone_number_required'.tr();
              if (v.trim().length != 11) return 'invalid_phone_format'.tr();
              return null;
            }),
        const SizedBox(height: 14),
        CustomTextField(controller: _addressController, label: 'address'.tr(),
            hint: 'enter_address'.tr(), prefixIcon: Icons.location_on,
            maxLines: 3, enabled: _isEditing,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'address_required'.tr() : null),
        const SizedBox(height: 14),
        CustomTextField(controller: _bioController, label: 'About',
            hint: 'Tell something about yourself or your organization',
            prefixIcon: Icons.info, maxLines: 4, enabled: _isEditing),
        if (_isEditing) ...[
          const SizedBox(height: 20),
          CustomButton(
            text: _isLoading ? 'saving'.tr() : 'save_changes'.tr(),
            onPressed: _isLoading ? null : _save,
            fullWidth: true, icon: Icons.save,
          ),
        ],
      ]),
    ));
  }

  Widget _buildSettings(ColorScheme colorScheme) {
    return Column(children: [
      // Theme card
      Card(elevation: 2, child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.palette), const SizedBox(width: 8),
            Text('theme_settings'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 14),
          Text('color_theme'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Consumer<ThemeProvider>(builder: (context, tp, _) {
            return Wrap(spacing: 8, children: ThemeVariant.values.map((v) {
              final sel = tp.currentVariant == v;
              return GestureDetector(onTap: () => tp.setThemeVariant(v),
                child: Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: v.primaryColor, shape: BoxShape.circle,
                    border: Border.all(color: sel ? Colors.black : Colors.grey.shade300,
                        width: sel ? 3 : 1)),
                  child: sel ? const Icon(Icons.check, color: Colors.white) : null),
              );
            }).toList());
          }),
          const SizedBox(height: 14),
          Text('appearance'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Consumer<ThemeProvider>(builder: (context, tp, _) {
            return DropdownButton<ThemeMode>(
              value: tp.themeMode,
              onChanged: (m) { if (m != null) tp.setThemeMode(m); },
              items: [
                DropdownMenuItem(value: ThemeMode.light, child: Text('light_appearance'.tr())),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('dark_appearance'.tr())),
              ],
            );
          }),
        ],
      ))),
      const SizedBox(height: 14),
      // Language card
      Card(elevation: 2, child: ListTile(
        leading: const Icon(Icons.language),
        title: Text('language_settings'.tr()),
        subtitle: Text('choose_language'.tr()),
        trailing: DropdownButton<String>(
          value: context.locale.languageCode,
          onChanged: (code) {
            if (code == null) return;
            final lp = Provider.of<LanguageProvider>(context, listen: false);
            AppLanguage lang = AppLanguage.english;
            if (code == 'ur') lang = AppLanguage.urdu;
            if (code == 'ru') lang = AppLanguage.romanUrdu;
            lp.setLanguage(lang, context);
          },
          items: [
            DropdownMenuItem(value: 'en', child: Text('english'.tr())),
            DropdownMenuItem(value: 'ur', child: Text('urdu'.tr())),
            DropdownMenuItem(value: 'ru', child: Text('roman_urdu'.tr())),
          ],
        ),
      )),
      const SizedBox(height: 14),
      CustomButton(text: 'logout'.tr(), onPressed: _logout,
          fullWidth: true, variant: ButtonVariant.outlined, icon: Icons.logout),
    ]);
  }
}
