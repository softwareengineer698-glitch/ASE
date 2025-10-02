import 'package:flutter/material.dart';
import '../../models/user_profile_model.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? profile;

  const EditProfileScreen({
    super.key,
    this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _organizationController;
  late TextEditingController _addressController;
  late TextEditingController _bioController;
  
  UserRole _selectedRole = UserRole.donor;
  bool _isLoading = false;
  bool _isNewProfile = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final profile = widget.profile;
    _isNewProfile = profile == null;

    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _organizationController = TextEditingController(text: profile?.organization ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    
    _selectedRole = profile?.role ?? UserRole.donor;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewProfile ? 'Create Profile' : 'Edit Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      child: widget.profile?.profileImageUrl != null
                          ? null
                          : Text(
                              _getInitials(),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement image picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image upload coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Change Photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Basic Information Section
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => UserProfile(
                  id: '',
                  name: '',
                  email: '',
                  phone: '',
                  role: _selectedRole,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ).validateName(value),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => UserProfile(
                  id: '',
                  name: '',
                  email: '',
                  phone: '',
                  role: _selectedRole,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ).validateEmail(value),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => UserProfile(
                  id: '',
                  name: '',
                  email: '',
                  phone: '',
                  role: _selectedRole,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ).validatePhone(value),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Role Selection
              const Text(
                'Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<UserRole>(
                      title: const Text('Food Donor'),
                      subtitle: const Text('Restaurant, store, individual'),
                      value: UserRole.donor,
                      groupValue: _selectedRole,
                      onChanged: _isNewProfile ? (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      } : null,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserRole>(
                      title: const Text('NGO Partner'),
                      subtitle: const Text('Non-profit organization'),
                      value: UserRole.ngo,
                      groupValue: _selectedRole,
                      onChanged: _isNewProfile ? (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      } : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Organization Field (for NGOs)
              if (_selectedRole == UserRole.ngo) ...[
                const Text(
                  'Organization Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _organizationController,
                  decoration: const InputDecoration(
                    labelText: 'Organization Name *',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => UserProfile(
                    id: '',
                    name: '',
                    email: '',
                    phone: '',
                    role: _selectedRole,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ).validateOrganization(value),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
              ],

              // Additional Information Section
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Bio Field
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about yourself...',
                ),
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                            Text('Saving...'),
                          ],
                        )
                      : Text(
                          _isNewProfile ? 'Create Profile' : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              if (!_isNewProfile) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return 'U';
    
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return nameParts[0][0].toUpperCase();
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      
      if (_isNewProfile) {
        success = await _profileService.createProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          organization: _organizationController.text.trim().isEmpty 
              ? null 
              : _organizationController.text.trim(),
          address: _addressController.text.trim().isEmpty 
              ? null 
              : _addressController.text.trim(),
          bio: _bioController.text.trim().isEmpty 
              ? null 
              : _bioController.text.trim(),
        );
      } else {
        final updatedProfile = widget.profile!.copyWith(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          organization: _organizationController.text.trim().isEmpty 
              ? null 
              : _organizationController.text.trim(),
          address: _addressController.text.trim().isEmpty 
              ? null 
              : _addressController.text.trim(),
          bio: _bioController.text.trim().isEmpty 
              ? null 
              : _bioController.text.trim(),
        );
        
        success = await _profileService.updateProfile(updatedProfile);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNewProfile ? 'Profile created successfully!' : 'Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
