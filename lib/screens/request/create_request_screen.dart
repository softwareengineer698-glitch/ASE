import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_request_service.dart';
import '../../models/food_request_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final FoodRequestService _requestService = FoodRequestService();
  
  final _foodTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedUnit = RequestUnit.kg;
  String _selectedFoodType = FoodType.freshVegetables;
  bool _isUrgent = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  
  bool _isLoading = false;
  final List<String> _foodTypes = FoodType.values;
  final List<String> _units = RequestUnit.values;

  @override
  void dispose() {
    _foodTypeController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        _showError('Please sign in to create a request');
        return;
      }

      // Use custom food type if "Other" is selected
      final foodType = _selectedFoodType == FoodType.other
          ? _foodTypeController.text.trim()
          : _selectedFoodType;

      await _requestService.createRequest(
        userId: user.uid,
        userName: user.userName ?? user.email.split('@')[0],
        organizationName: user.organizationName ?? 'NGO',
        foodType: foodType,
        description: _descriptionController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        unit: _selectedUnit,
        neededBy: _selectedDate,
        location: _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        isUrgent: _isUrgent,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('request_created_success'.tr());
      }
    } catch (e) {
      _showError('Failed to create request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('create_request'.tr()),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'request_info_message'.tr(),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Food type dropdown
                    Text(
                      'food_type'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFoodType,
                      items: _foodTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFoodType = value!;
                          if (value != FoodType.other) {
                            _foodTypeController.clear();
                          }
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Show text field if "Other" is selected
                    if (_selectedFoodType == FoodType.other) ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _foodTypeController,
                        label: 'specify_food_type'.tr(),
                        hint: 'enter_food_type'.tr(),
                        prefixIcon: Icons.restaurant,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'food_type_required'.tr() : null,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Quantity and Unit row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            controller: _quantityController,
                            label: 'quantity'.tr(),
                            hint: 'enter_quantity'.tr(),
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.numbers,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'quantity_required'.tr();
                              }
                              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                return 'invalid_quantity'.tr();
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('unit'.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedUnit,
                                items: _units.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedUnit = value!),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'description'.tr(),
                      hint: 'describe_food_needed'.tr(),
                      prefixIcon: Icons.description,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Date picker
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: colorScheme.primary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'needed_by'.tr(),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Location (optional)
                    CustomTextField(
                      controller: _locationController,
                      label: 'location_optional'.tr(),
                      hint: 'enter_pickup_location'.tr(),
                      prefixIcon: Icons.location_on,
                    ),

                    const SizedBox(height: 16),

                    // Urgent toggle
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isUrgent ? Icons.priority_high : Icons.schedule,
                            color: _isUrgent ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'urgent_request'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'urgent_request_desc'.tr(),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isUrgent,
                            onChanged: (value) => setState(() => _isUrgent = value),
                            activeColor: Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    CustomButton(
                      text: 'submit_request'.tr(),
                      onPressed: _isLoading ? null : _createRequest,
                      isLoading: _isLoading,
                      fullWidth: true,
                      icon: Icons.send,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}