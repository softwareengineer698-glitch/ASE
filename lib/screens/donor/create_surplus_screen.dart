import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/surplus_service.dart';
import '../../services/notification_service.dart';
import '../../models/surplus_report_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CreateSurplusScreen extends StatefulWidget {
  const CreateSurplusScreen({super.key});

  @override
  State<CreateSurplusScreen> createState() => _CreateSurplusScreenState();
}

class _CreateSurplusScreenState extends State<CreateSurplusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _foodTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SurplusService _surplusService = SurplusService();
  
  DateTime _selectedExpiry = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  @override
  void dispose() {
    _foodTypeController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiry,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedExpiry) {
      setState(() {
        _selectedExpiry = picked;
      });
    }
  }

  Future<void> _createSurplus() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create surplus reports')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final surplus = SurplusReportModel(
        id: '', // Will be set by Firestore
        donorId: user.uid,
        foodType: _foodTypeController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        expiry: _selectedExpiry,
        timestamp: DateTime.now(),
        description: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
        status: 'available',
      );

      await _surplusService.createSurplusReport(surplus);

      // Show notification
      NotificationService().notifySurplusReported(
        donorName: 'You', // TODO: Get actual donor name from profile
        foodType: surplus.foodType,
        quantity: surplus.quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Surplus report created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating surplus: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Surplus Report'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Report Food Surplus',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Help reduce food waste by sharing your surplus',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Food Type with suggestions
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _foodTypeController,
                    label: 'Food Type',
                    prefixIcon: Icons.fastfood,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the food type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Suggestions:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      'Fresh Vegetables',
                      'Fruits',
                      'Bread & Bakery',
                      'Dairy Products',
                      'Cooked Meals',
                      'Rice & Grains',
                      'Canned Foods',
                      'Beverages',
                    ].map((suggestion) => GestureDetector(
                      onTap: () {
                        _foodTypeController.text = suggestion;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity
              CustomTextField(
                controller: _quantityController,
                label: 'Quantity (kg/units)',
                prefixIcon: Icons.scale,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the quantity';
                  }
                  final quantity = int.tryParse(value.trim());
                  if (quantity == null || quantity <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Expiry Date
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.green),
                  title: const Text('Expiry Date'),
                  subtitle: Text(
                    '${_selectedExpiry.day}/${_selectedExpiry.month}/${_selectedExpiry.year}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectExpiryDate,
                ),
              ),
              const SizedBox(height: 16),

              // Description (Optional)
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                prefixIcon: Icons.description,
                maxLines: 3,
                validator: null, // Optional field
              ),
              const SizedBox(height: 32),

              // Create Button
              CustomButton(
                text: 'Create Surplus Report',
                onPressed: _isLoading ? null : _createSurplus,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),

              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your surplus will be visible to NGOs who can request it to help those in need.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
