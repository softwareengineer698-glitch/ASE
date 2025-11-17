import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/profile_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = FirestoreProfileService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _organizationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ProfileModel? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _organizationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;

    try {
      final profile = await _profileService.getProfile(user.uid);
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          
          // Populate controllers
          _nameController.text = profile?.name ?? '';
          _phoneController.text = profile?.phone ?? '';
          _addressController.text = profile?.address ?? '';
          _organizationController.text = profile?.organization ?? '';
          _descriptionController.text = profile?.description ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) return;

    try {
      final profile = ProfileModel(
        userId: user.uid,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        organization: _organizationController.text.trim().isNotEmpty ? _organizationController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        updatedAt: DateTime.now(),
      );

      await _profileService.saveProfile(profile);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please sign in to view profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: user.role == UserRole.donor ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadProfile(); // Reset form
              },
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: user.role == UserRole.donor 
                              ? Colors.green 
                              : Colors.blue,
                            child: Text(
                              _getInitials(user.email),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _profile?.name ?? 'No name set',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                              user.role.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: user.role == UserRole.donor 
                              ? Colors.green 
                              : Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email (read-only)
                          _buildInfoField(
                            'Email',
                            user.email,
                            Icons.email,
                            isReadOnly: true,
                          ),
                          const SizedBox(height: 12),

                          // Name
                          _buildEditableField(
                            'Name',
                            _nameController,
                            Icons.person,
                          ),
                          const SizedBox(height: 12),

                          // Phone
                          _buildEditableField(
                            'Phone',
                            _phoneController,
                            Icons.phone,
                          ),
                          const SizedBox(height: 12),

                          // Address
                          _buildEditableField(
                            'Address',
                            _addressController,
                            Icons.location_on,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),

                          // Organization (for NGOs)
                          if (user.role == UserRole.ngo) ...[
                            _buildEditableField(
                              'Organization',
                              _organizationController,
                              Icons.business,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Description
                          _buildEditableField(
                            'Description',
                            _descriptionController,
                            Icons.description,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInfoField(
                            'User ID',
                            user.uid,
                            Icons.fingerprint,
                            isReadOnly: true,
                          ),
                          const SizedBox(height: 12),
                          
                          _buildInfoField(
                            'Role',
                            user.role.displayName,
                            Icons.admin_panel_settings,
                            isReadOnly: true,
                          ),
                          const SizedBox(height: 12),
                          
                          if (_profile?.updatedAt != null)
                            _buildInfoField(
                              'Last Updated',
                              _formatDate(_profile!.updatedAt!),
                              Icons.update,
                              isReadOnly: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: _isEditing,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
            hintText: _isEditing ? 'Enter $label' : 'Not set',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    IconData icon, {
    bool isReadOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
            color: isReadOnly ? Colors.grey.shade50 : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : 'Not set',
                  style: TextStyle(
                    color: value.isNotEmpty ? Colors.black : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'U';
    final parts = email.split('@')[0].split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email[0].toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
