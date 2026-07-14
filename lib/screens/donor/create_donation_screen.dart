import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/donation_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/donation_service.dart';
import '../../widgets/ui_helpers.dart';
import '../../widgets/voice_input_widget.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _donationService = DonationService();
  final _cloudinaryService = CloudinaryService();
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Vegetables';
  DonationItemType _selectedItemType = DonationItemType.food;
  String _selectedUnit = 'kg';
  DateTime _expiryDate = DateTime.now().add(const Duration(hours: 24));
  TimeOfDay _expiryTimeOfDay = TimeOfDay.now();
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;
  // Upload progress: 0.0 – 1.0 while uploading, null when idle
  double? _uploadProgress;
  double? _latitude;
  double? _longitude;
  bool _fetchingLocation = false;

  // ── Location autocomplete ────────────────────────────────────────────────
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _loadingSuggestions = false;
  Timer? _debounce;
  final FocusNode _locationFocus = FocusNode();

  // ── Categories per item type ──────────────────────────────────────────────
  static const Map<DonationItemType, List<String>> _categoryMap = {
    DonationItemType.food: [
      'Vegetables',
      'Fruits',
      'Grains',
      'Dairy',
      'Bakery',
      'Meat',
      'Seafood',
      'Prepared Foods',
      'Beverages',
      'Other'
    ],
    DonationItemType.clothes: [
      'Shirts',
      'Pants',
      'Shoes',
      'Jackets',
      'Children Clothes',
      'Other'
    ],
    DonationItemType.books: [
      'Textbooks',
      'Fiction',
      'Non-Fiction',
      'Children Books',
      'Other'
    ],
    DonationItemType.medicines: [
      'OTC Medicines',
      'Vitamins',
      'First Aid',
      'Other'
    ],
    DonationItemType.household: [
      'Furniture',
      'Kitchen',
      'Bedding',
      'Electronics',
      'Other'
    ],
    DonationItemType.other: ['Other'],
  };

  static const List<String> _units = [
    'kg',
    'g',
    'liters',
    'ml',
    'pieces',
    'boxes',
    'bags',
    'bottles',
    'containers',
    'pairs',
    'sets'
  ];

  List<String> get _categories => _categoryMap[_selectedItemType] ?? ['Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _locationFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, _) {
        if (authProvider.user == null) {
          return const Scaffold(body: Center(child: Text('Please sign in')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('create_donation'.tr()),
            backgroundColor: themeProvider.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploadProgress != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${((_uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text('Uploading photos...'),
                      ] else ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Creating donation...'),
                      ],
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('item_type'.tr()),
                        const SizedBox(height: 12),
                        _buildItemTypeSelector(),
                        const SizedBox(height: 24),
                        _sectionHeader('basic_information'.tr()),
                        const SizedBox(height: 12),
                        _buildTitleField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 24),
                        _sectionHeader('category_details'.tr()),
                        const SizedBox(height: 12),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 16),
                        _buildQuantityRow(),
                        const SizedBox(height: 24),
                        _sectionHeader('location_details'.tr()),
                        const SizedBox(height: 12),
                        _buildLocationField(),
                        const SizedBox(height: 24),
                        _sectionHeader('expiry_details'.tr()),
                        const SizedBox(height: 12),
                        _buildExpirySelector(),
                        const SizedBox(height: 24),
                        _sectionHeader('photos'.tr()),
                        const SizedBox(height: 12),
                        _buildImageSelector(),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _submitDonation,
                            icon: const Icon(Icons.send_rounded),
                            label: Text('create_donation'.tr(),
                                style: const TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      );

  // ── Item type chip selector ───────────────────────────────────────────────
  Widget _buildItemTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DonationItemType.values
          .where((type) => type != DonationItemType.medicines)
          .map((type) {
        final selected = _selectedItemType == type;
        return FilterChip(
          label: Text(type.displayName),
          selected: selected,
          onSelected: (_) => setState(() {
            _selectedItemType = type;
            // reset category to first in new type
            _selectedCategory = _categoryMap[type]!.first;
          }),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildTitleField() => TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: 'donation_title'.tr(),
          hintText: 'enter_donation_title'.tr(),
          border: const OutlineInputBorder(),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: VoiceInputButton(
              controller: _titleController,
              hintText: 'Say the donation title',
            ),
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'please_enter_title'.tr();
          if (v.trim().length < 3) return 'title_too_short'.tr();
          return null;
        },
      );

  Widget _buildDescriptionField() => TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          labelText: 'description'.tr(),
          hintText: 'enter_description'.tr(),
          border: const OutlineInputBorder(),
          helperText: '${_descriptionController.text.trim().length}/100 characters minimum',
          helperStyle: TextStyle(
            color: _descriptionController.text.trim().length >= 100
                ? Colors.green
                : Colors.grey[600],
            fontSize: 11,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: VoiceInputButton(
              controller: _descriptionController,
              hintText: 'Describe the donation',
              appendMode: true,
              onResult: () => setState(() {}),
            ),
          ),
        ),
        maxLines: 4,
        onChanged: (_) => setState(() {}),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'please_enter_description'.tr();
          }
          if (v.trim().length < 100) {
            return 'Description must be at least 100 characters (${v.trim().length}/100)';
          }
          return null;
        },
      );

  Widget _buildCategoryDropdown() => DropdownButtonFormField<String>(
        initialValue: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'category'.tr(),
          border: const OutlineInputBorder(),
        ),
        items: _categories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _selectedCategory = v!),
      );

  Widget _buildQuantityRow() => Row(
        children: [
          Flexible(
            flex: 3,
            child: TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'quantity'.tr(),
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'please_enter_quantity'.tr();
                }
                final q = double.tryParse(v.trim());
                if (q == null || q <= 0) return 'invalid_quantity'.tr();
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedUnit,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'unit'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: _units
                  .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u.tr(), overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedUnit = v!),
            ),
          ),
        ],
      );

  // ── Location autocomplete search via Nominatim ───────────────────────────
  Future<void> _searchLocation(String query) async {
    if (query.trim().length < 3) {
      setState(() { _locationSuggestions = []; });
      return;
    }
    setState(() => _loadingSuggestions = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&addressdetails=1&limit=6',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'CareCircle/1.0 (CareCircle@app.com)',
      });
      if (res.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        if (mounted) setState(() => _locationSuggestions = data);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _onLocationChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocation(value);
    });
  }

  void _selectSuggestion(Map<String, dynamic> place) {
    final name = place['display_name'] as String? ?? '';
    final lat = double.tryParse(place['lat']?.toString() ?? '');
    final lon = double.tryParse(place['lon']?.toString() ?? '');
    setState(() {
      _locationController.text = name;
      _latitude = lat;
      _longitude = lon;
      _locationSuggestions = [];
    });
    _locationFocus.unfocus();
  }

  Widget _buildLocationField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                focusNode: _locationFocus,
                decoration: InputDecoration(
                  labelText: 'pickup_location'.tr(),
                  hintText: 'Search for a location...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _loadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _locationController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _locationController.clear();
                                setState(() {
                                  _locationSuggestions = [];
                                  _latitude = null;
                                  _longitude = null;
                                });
                              },
                            )
                          : null,
                ),
                onChanged: _onLocationChanged,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'please_enter_location'.tr()
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            _fetchingLocation
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton.outlined(
                    onPressed: _fetchCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    tooltip: 'Use current location',
                  ),
          ]),

          // Suggestions dropdown
          if (_locationSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _locationSuggestions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (_, i) {
                  final place = _locationSuggestions[i];
                  final display =
                      place['display_name'] as String? ?? '';
                  // Short label: first part before comma
                  final shortName = display.split(',').first.trim();
                  // Sub-label: rest of the address
                  final subLabel = display
                      .split(',')
                      .skip(1)
                      .take(3)
                      .join(',')
                      .trim();

                  return InkWell(
                    onTap: () => _selectSuggestion(place),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(children: [
                        const Icon(Icons.location_on,
                            size: 18, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shortName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              if (subLabel.isNotEmpty)
                                Text(subLabel,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),

          // GPS coordinates indicator
          if (_latitude != null && _longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(children: [
                const Icon(Icons.gps_fixed, size: 13, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'GPS saved: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
              ]),
            ),
        ],
      );

  Widget _buildExpirySelector() {
    final dt = _expiryDate;
    final tod = _expiryTimeOfDay;
    final formatted =
        '${dt.day}/${dt.month}/${dt.year}  ${tod.format(context)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('expiry_time'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(formatted, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            TextButton(
              onPressed: _selectExpiry,
              child: Text('change'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image Selector ────────────────────────────────────────────────────────
  Widget _buildImageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImages.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('no_photos_selected'.tr(),
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  _selectedImages[i].path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedImages[i].path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 10,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedImages.removeAt(i)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text('gallery'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text('camera'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _selectExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time =
        await showTimePicker(context: context, initialTime: _expiryTimeOfDay);
    if (time == null || !mounted) return;

    setState(() {
      _expiryDate = date;
      _expiryTimeOfDay = time;
    });
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 75);
      if (images.isNotEmpty) {
        setState(() => _selectedImages.addAll(images));
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackBar(context, 'error_picking_images'.tr());
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final image =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
      if (image != null) {
        setState(() => _selectedImages.add(image));
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackBar(context, 'error_picking_images'.tr());
      }
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          UIHelper.showErrorSnackBar(context, 'Location services disabled');
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            UIHelper.showErrorSnackBar(context, 'Location permission denied');
          }
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);

      // Reverse geocode to get a readable address
      String locationText =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${position.latitude}&lon=${position.longitude}'
          '&format=json',
        );
        final res = await http.get(uri,
            headers: {'User-Agent': 'CareCircle/1.0 (CareCircle@app.com)'});
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final display = data['display_name'] as String?;
          if (display != null && display.isNotEmpty) {
            locationText = display;
          }
        }
      } catch (_) {}

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text = locationText;
        _locationSuggestions = [];
      });
    } catch (e) {
      if (mounted) {
        UIHelper.showErrorSnackBar(context, 'Failed to get location');
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  // ── Firebase Storage upload ───────────────────────────────────────────────
  /// Uploads [files] to Firebase Storage under donations/{donationId}/ and
  /// returns the list of download URLs. Reports overall progress via
  /// [onProgress] (0.0 – 1.0).
  Future<List<CloudinaryUploadResult>> _uploadImages(
    List<XFile> files,
    String donationId,
    void Function(double) onProgress,
  ) async {
    final uploads = <CloudinaryUploadResult>[];
    for (int i = 0; i < files.length; i++) {
      uploads.add(await _cloudinaryService.uploadDonationImage(
        file: files[i],
        donationId: donationId,
        index: i,
      ));
      onProgress((i + 1) / files.length);
    }
    return uploads;
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      UIHelper.showErrorSnackBar(context, 'please_add_at_least_one_photo'.tr());
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      final expiryDateTime = DateTime(
        _expiryDate.year,
        _expiryDate.month,
        _expiryDate.day,
        _expiryTimeOfDay.hour,
        _expiryTimeOfDay.minute,
      );

      // Create the Firestore document first to obtain its ID, then upload
      final donationId = await _donationService.createDonation(
        donorId: user.uid,
        donorName: user.userName ?? user.email.split('@')[0],
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        itemType: _selectedItemType,
        quantity: double.parse(_quantityController.text.trim()),
        unit: _selectedUnit,
        location: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageUrls: const [],
        expiryTime: expiryDateTime,
      );

      // Upload images and update the document with URLs
      final uploads = await _uploadImages(
        _selectedImages,
        donationId,
        (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      await _donationService.updateDonationImages(
        donationId,
        uploads.map((upload) => upload.secureUrl).toList(),
        publicIds: uploads.map((upload) => upload.publicId).toList(),
      );

      if (mounted) {
        setState(() => _uploadProgress = null);
        UIHelper.showSuccessSnackBar(
            context, 'donation_created_successfully'.tr());
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadProgress = null);
        UIHelper.showErrorSnackBar(
            context, '${'error_creating_donation'.tr()}: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
