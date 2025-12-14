// ============================================
// UPDATED: lib/screens/booking/booking_flow_screen.dart
// ============================================
// Replace your existing booking_flow_screen.dart with this version
// that includes payment processing

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/car_model.dart';
import '../../models/booking_model.dart';
import '../../models/payment_method_model.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class BookingFlowScreen extends StatefulWidget {
  final Car car;

  const BookingFlowScreen({Key? key, required this.car}) : super(key: key);

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _currentStep = 0;
  final _bookingService = BookingService();
  final _authService = AuthService();
  final _paymentService = PaymentService();
  bool _isLoading = false;

  // Form Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  DateTime _dropoffDate = DateTime.now().add(const Duration(days: 4));
  bool _insuranceIncluded = false;
  
  // Payment
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;
  bool _loadingPaymentMethods = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingPaymentMethods = true);
    try {
      final userId = _authService.userId;
      if (userId != null) {
        final methods = await _paymentService.getPaymentMethods(userId);
        setState(() {
          _paymentMethods = methods;
          // Auto-select default payment method
          _selectedPaymentMethod = methods.firstWhere(
            (m) => m.isDefault,
            orElse: () => methods.isNotEmpty ? methods.first : PaymentMethod(
              id: '', userId: '', cardHolderName: '', cardNumberLast4: '',
              cardType: '', expiryMonth: 1, expiryYear: 2024, createdAt: DateTime.now(),
            ),
          );
          _loadingPaymentMethods = false;
        });
      }
    } catch (e) {
      setState(() => _loadingPaymentMethods = false);
    }
  }

  int get _durationInDays {
    return _dropoffDate.difference(_pickupDate).inDays;
  }

  double get _totalPrice {
    double basePrice = widget.car.pricePerDay * _durationInDays;
    if (_insuranceIncluded) basePrice += (_durationInDays * 15);
    return basePrice;
  }

  Future<void> _completeBooking() async {
    // Validate payment method selected
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Step 1: Create booking
      final booking = Booking(
        id: '',
        userId: userId,
        carId: widget.car.id,
        pickupDate: _pickupDate,
        dropoffDate: _dropoffDate,
        pickupLocation: _pickupLocationController.text,
        dropoffLocation: _dropoffLocationController.text,
        totalPrice: _totalPrice,
        status: 'pending',
        insuranceIncluded: _insuranceIncluded,
        createdAt: DateTime.now(),
      );

      final createdBooking = await _bookingService.createBooking(booking);

      // Step 2: Process payment
      final paymentResult = await _paymentService.processPayment(
        bookingId: createdBooking.id,
        userId: userId,
        paymentMethodId: _selectedPaymentMethod!.id,
        amount: _totalPrice,
      );

      // Step 3: Update booking status to confirmed
      await _bookingService.updateBookingStatus(createdBooking.id, 'confirmed');

      if (mounted) {
        // Show success dialog with payment details
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Transaction ID: ${paymentResult['transaction_id']}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount Paid: \$${paymentResult['amount'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your booking has been confirmed and payment processed successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Booking'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(24),
            color: AppTheme.lightColor,
            child: Row(
              children: [
                _buildStepIndicator(0, 'Details'),
                Expanded(child: _buildStepLine(0)),
                _buildStepIndicator(1, 'Extras'),
                Expanded(child: _buildStepLine(1)),
                _buildStepIndicator(2, 'Payment'),
              ],
            ),
          ),

          // Step Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentStep--);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: _currentStep == 2 ? 'Confirm & Pay' : 'Continue',
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _completeBooking();
                        }
                      },
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive ? AppTheme.primaryGradient : null,
            color: isActive ? null : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.primaryColor : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: isActive ? AppTheme.primaryColor : Colors.grey[300],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalDetails();
      case 1:
        return _buildExtrasStep();
      case 2:
        return _buildPaymentStep();
      default:
        return Container();
    }
  }

  Widget _buildPersonalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Information', style: AppTheme.heading2),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _fullNameController,
          label: 'Full Name',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _licenseController,
          label: 'License Number',
          prefixIcon: Icons.credit_card_outlined,
        ),
        const SizedBox(height: 32),
        const Text('Rental Details', style: AppTheme.heading3),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _pickupLocationController,
          label: 'Pickup Location',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _dropoffLocationController,
          label: 'Dropoff Location',
          prefixIcon: Icons.flag_outlined,
        ),
      ],
    );
  }

  Widget _buildExtrasStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Options', style: AppTheme.heading2),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: SwitchListTile(
            value: _insuranceIncluded,
            onChanged: (value) {
              setState(() => _insuranceIncluded = value);
            },
            title: const Text(
              'Insurance Coverage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('\$15 per day'),
            secondary: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppTheme.accentColor,
              ),
            ),
            activeColor: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.lightColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coverage includes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Damage protection'),
              _buildBulletPoint('Theft coverage'),
              _buildBulletPoint('Third-party liability'),
              _buildBulletPoint('24/7 roadside assistance'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Information', style: AppTheme.heading2),
        const SizedBox(height: 24),
        
        // Booking Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.car.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.car.type,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white30),
              const SizedBox(height: 20),
              _buildSummaryRow(
                'Duration',
                '$_durationInDays days',
              ),
              _buildSummaryRow(
                'Base Price',
                '\$${(widget.car.pricePerDay * _durationInDays).toStringAsFixed(2)}',
              ),
              if (_insuranceIncluded)
                _buildSummaryRow(
                  'Insurance',
                  '\$${(_durationInDays * 15).toStringAsFixed(2)}',
                ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white30),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Total',
                '\$${_totalPrice.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Payment Method Selection
        const Text('Select Payment Method', style: AppTheme.heading3),
        const SizedBox(height: 16),
        
        if (_loadingPaymentMethods)
          const Center(child: CircularProgressIndicator())
        else if (_paymentMethods.isEmpty)
          Center(
            child: Column(
              children: [
                const Text('No payment methods available'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate to add payment method
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add a payment method in your profile'),
                      ),
                    );
                  },
                  child: const Text('Add Payment Method'),
                ),
              ],
            ),
          )
        else
          ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() => _selectedPaymentMethod = value);
        },
        title: Text(
          method.cardType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('**** ${method.cardNumberLast4}'),
        secondary: Icon(
          Icons.credit_card,
          color: isSelected ? AppTheme.primaryColor : Colors.grey,
        ),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.white70,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 24 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}