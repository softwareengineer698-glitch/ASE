import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../auth/sign_in_screen.dart';

class NGOProfileScreen extends StatefulWidget {
  const NGOProfileScreen({super.key});

  @override
  State<NGOProfileScreen> createState() => _NGOProfileScreenState();
}

class _NGOProfileScreenState extends State<NGOProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic>? _profileData;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          _profileData = doc.data();
          _populateControllers();
        } else {
          // Create default profile data
          _profileData = {
            'name': user.email.split('@')[0],
            'email': user.email,
            'phone': '',
            'organization': '',
            'address': '',
            'bio': '',
            'role': 'ngo',
            'createdAt': DateTime.now().toIso8601String(),
          };
          _populateControllers();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _populateControllers() {
    if (_profileData != null) {
      _nameController.text = _profileData!['name'] ?? '';
      _emailController.text = _profileData!['email'] ?? '';
      _phoneController.text = _profileData!['phone'] ?? '';
      _organizationController.text = _profileData!['organization'] ?? '';
      _addressController.text = _profileData!['address'] ?? '';
      _bioController.text = _profileData!['bio'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        final updatedData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'organization': _organizationController.text.trim(),
          'address': _addressController.text.trim(),
          'bio': _bioController.text.trim(),
          'role': 'ngo',
          'updatedAt': DateTime.now().toIso8601String(),
          'createdAt':
              _profileData?['createdAt'] ?? DateTime.now().toIso8601String(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updatedData, SetOptions(merge: true));

        _profileData = updatedData;
        setState(() => _isEditing = false);

        _showSuccessSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImageUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('change_profile_picture'.tr()),
        content: Text('choose_image_source'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: Text('gallery'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
            child: Text('camera'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showSuccessSnackBar('Profile picture updated from gallery');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image from gallery: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showSuccessSnackBar('Profile picture updated from camera');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take picture: $e');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('confirm_logout'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading && _profileData == null) {
      return const Scaffold(
        body: Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('ngo_profile'.tr()),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              tooltip: 'edit_profile'.tr(),
            ),
          if (_isEditing)
            IconButton(
              onPressed: () {
                setState(() => _isEditing = false);
                _populateControllers(); // Reset changes
              },
              icon: const Icon(Icons.close),
              tooltip: 'cancel'.tr(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(colorScheme),
                const SizedBox(height: 32),

                // Profile Form
                _buildProfileForm(colorScheme),
                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(colorScheme),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    // Note: Verification badge removed - all NGOs are auto-verified per requirements
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : null,
                  child: _selectedImage == null
                      ? Text(
                          _getInitials(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _showImageUploadDialog,
                      tooltip: 'Change Profile Picture',
                    ),
                  ),
                ),
                // Note: Verification badge removed - all NGOs are auto-verified
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _profileData?['organization'] ?? 'Organization Name',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Note: Status badge simplified - all NGOs are automatically verified
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Active NGO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'organization_information'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _organizationController,
              label: 'organization_name'.tr(),
              hint: 'enter_organization_name'.tr(),
              prefixIcon: Icons.business,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'organization_name_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nameController,
              label: 'contact_person_name'.tr(),
              hint: 'enter_contact_person_name'.tr(),
              prefixIcon: Icons.person,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'contact_person_name_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'email_address'.tr(),
              hint: 'enter_email_address'.tr(),
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              enabled: false, // Email should not be editable
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'email_required'.tr();
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'enter_valid_email'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: 'phone_number'.tr(),
              hint: 'enter_phone_number'.tr(),
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'phone_number_required'.tr();
                }
                if (value.trim().length != 11) {
                  return 'invalid_phone_format'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _addressController,
              label: 'address'.tr(),
              hint: 'enter_organization_address'.tr(),
              prefixIcon: Icons.location_on,
              maxLines: 3,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'address_required'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _bioController,
              label: 'about_organization'.tr(),
              hint: 'tell_about_organization'.tr(),
              prefixIcon: Icons.info,
              maxLines: 4,
              enabled: _isEditing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Column(
      children: [
        if (_isEditing) ...[
          CustomButton(
            text: _isLoading ? 'saving'.tr() : 'save_changes'.tr(),
            onPressed: _isLoading ? null : _saveProfile,
            fullWidth: true,
            icon: Icons.save,
          ),
          const SizedBox(height: 16),
        ],

        // Theme Settings
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette),
                    const SizedBox(width: 8),
                    Text(
                      'theme_settings'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Theme Colors
                Text(
                  'color_theme'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Wrap(
                      spacing: 8,
                      children: ThemeVariant.values.map((variant) {
                        final isSelected =
                            themeProvider.currentVariant == variant;
                        return GestureDetector(
                          onTap: () => themeProvider.setThemeVariant(variant),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: variant.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Theme Mode
                Text(
                  'appearance'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return DropdownButton<ThemeMode>(
                      value: themeProvider.themeMode,
                      onChanged: (ThemeMode? mode) {
                        if (mode != null) {
                          themeProvider.setThemeMode(mode);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('light_appearance'.tr()),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('dark_appearance'.tr()),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Language Settings
        Card(
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text('language_settings'.tr()),
            subtitle: Text('choose_language'.tr()),
            trailing: DropdownButton<String>(
              value: context.locale.languageCode,
              onChanged: (String? languageCode) {
                if (languageCode != null) {
                  final provider =
                      Provider.of<LanguageProvider>(context, listen: false);
                  AppLanguage lang = AppLanguage.english;
                  if (languageCode == 'ur') lang = AppLanguage.urdu;
                  if (languageCode == 'ru') lang = AppLanguage.romanUrdu;
                  provider.setLanguage(lang, context);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('english'.tr()),
                ),
                DropdownMenuItem(
                  value: 'ur',
                  child: Text('urdu'.tr()),
                ),
                DropdownMenuItem(
                  value: 'ru',
                  child: Text('roman_urdu'.tr()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Logout Button
        CustomButton(
          text: 'logout'.tr(),
          onPressed: _logout,
          fullWidth: true,
          variant: ButtonVariant.outlined,
          icon: Icons.logout,
        ),
      ],
    );
  }

  String _getInitials() {
    final orgName = _profileData?['organization'] ?? '';
    final contactName = _profileData?['name'] ?? '';

    if (orgName.isNotEmpty) {
      final words = orgName.split(' ');
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words.isNotEmpty) {
        return words[0][0].toUpperCase();
      }
    }

    if (contactName.isNotEmpty) {
      return contactName[0].toUpperCase();
    }

    return 'N';
  }
}