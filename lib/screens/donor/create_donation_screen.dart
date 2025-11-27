import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/donation_service.dart';
import '../../services/location_service.dart';
import '../../widgets/ui_helpers.dart';
import 'dart:io';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _donationService = DonationService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _locationController = TextEditingController();

  // Form state
  String _selectedCategory = 'Vegetables';
  DateTime _expiryTime = DateTime.now().add(const Duration(hours: 24));
  List<File> _selectedImages = [];
  bool _isLoading = false;
  LocationDetails? _selectedLocation;

  // Categories
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Bakery',
    'Meat',
    'Seafood',
    'Prepared Foods',
    'Beverages',
    'Other',
  ];

  // Common units
  final List<String> _commonUnits = [
    'kg',
    'liters',
    'pieces',
    'boxes',
    'bags',
    'bottles',
    'containers',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Please sign in to create a donation')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('create donation'.tr()),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: _isLoading
              ? const LoadingWidget(message: 'Creating donation...')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Section
                        _buildSectionHeader('basic information'.tr()),
                        const SizedBox(height: 16),
                        _buildTitleField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 24),

                        // Category Section
                        _buildSectionHeader('category details'.tr()),
                        const SizedBox(height: 16),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 16),
                        _buildQuantityFields(),
                        const SizedBox(height: 24),

                        // Location Section
                        _buildSectionHeader('location details'.tr()),
                        const SizedBox(height: 16),
                        _buildLocationField(),
                        const SizedBox(height: 24),

                        // Expiry Section
                        _buildSectionHeader('expiry details'.tr()),
                        const SizedBox(height: 16),
                        _buildExpirySelector(),
                        const SizedBox(height: 24),

                        // Images Section
                        _buildSectionHeader('photos'.tr()),
                        const SizedBox(height: 16),
                        _buildImageSelector(),
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitDonation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'create donation'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'donation title'.tr(),
        hintText: 'enter donation title'.tr(),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'please enter title'.tr();
        }
        if (value.trim().length < 3) {
          return 'title too short'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'description'.tr(),
        hintText: 'enter description'.tr() + ' (min 100 characters)',
        border: const OutlineInputBorder(),
        helperText:
            '${_descriptionController.text.length}/100 characters minimum',
        helperStyle: TextStyle(
          color: _descriptionController.text.length >= 100
              ? Colors.green
              : Colors.grey,
        ),
      ),
      maxLines: 4,
      onChanged: (value) {
        setState(() {}); // Rebuild to update character count
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'please enter description'.tr();
        }
        if (value.trim().length < 100) {
          return 'Description must be at least 100 characters long (${value.trim().length}/100)';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'category'.tr(),
        border: const OutlineInputBorder(),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildQuantityFields() {
    return Row(
      children: [
        Flexible(
          flex: 3,
          child: TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'quantity'.tr(),
              hintText: '0',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'please enter quantity'.tr();
              }
              final quantity = double.tryParse(value);
              if (quantity == null || quantity <= 0) {
                return 'invalid quantity'.tr();
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _unitController.text.isEmpty ? 'kg' : _unitController.text,
            decoration: InputDecoration(
              labelText: 'unit'.tr(),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            isExpanded: true,
            items: _commonUnits.map((unit) {
              return DropdownMenuItem(
                value: unit,
                child: Text(
                  unit,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _unitController.text = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return LocationAutocomplete(
      controller: _locationController,
      onLocationSelected: (location) {
        setState(() {
          _selectedLocation = location;
        });
      },
      hintText: 'Enter pickup location (autocomplete enabled)',
    );
  }

  Widget _buildExpirySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'expiry_time'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'selected_expiry'.tr() +
                  ': ${_expiryTime.day}/${_expiryTime.month}/${_expiryTime.year} ${_expiryTime.hour}:${_expiryTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectExpiryTime,
                icon: const Icon(Icons.access_time),
                label: Text('change_expiry'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Add Photos',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedImages.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'no_photos_selected'.tr(),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(image),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text('Add Photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expiryTime,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expiryTime),
      );

      if (selectedTime != null) {
        setState(() {
          _expiryTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      UIHelper.showErrorSnackBar(context, 'error_picking_images'.tr());
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      UIHelper.showErrorSnackBar(context, 'please_add_at_least_one_photo'.tr());
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      UIHelper.showErrorSnackBar(context, 'please_sign_in'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll use empty URLs. In production, you'd upload images to Firebase Storage
      final imageUrls = <String>[];

      await _donationService.createDonation(
        donorId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unitController.text.trim(),
        location: _locationController.text.trim(),
        imageUrls: imageUrls,
        expiryTime: _expiryTime,
      );

      UIHelper.showSuccessSnackBar(
          context, 'donation_created_successfully'.tr());
      Navigator.pop(context);
    } catch (e) {
      UIHelper.showErrorSnackBar(
          context, 'error_creating_donation'.tr() + ': $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
