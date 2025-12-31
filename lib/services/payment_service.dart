import '../config/supabase_config.dart';
import '../models/payment_method_model.dart';

class PaymentService {
  final _supabase = SupabaseConfig.client;

  // Get user's payment methods
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    final response = await _supabase
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return (response as List).map((json) => PaymentMethod.fromJson(json)).toList();
  }

  // Add payment method
  Future<PaymentMethod> addPaymentMethod({
    required String userId,
    required String cardHolderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    bool setAsDefault = false,
  }) async {
    // Validate card (dummy validation)
    if (!_validateCardNumber(cardNumber)) {
      throw Exception('Invalid card number');
    }

    // Get card type
    final cardType = _getCardType(cardNumber);
    
    // Get last 4 digits
    final last4 = cardNumber.substring(cardNumber.length - 4);

    // If setting as default, unset other defaults
    if (setAsDefault) {
      await _supabase
          .from('payment_methods')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    final response = await _supabase
        .from('payment_methods')
        .insert({
          'user_id': userId,
          'card_holder_name': cardHolderName,
          'card_number_last4': last4,
          'card_type': cardType,
          'expiry_month': expiryMonth,
          'expiry_year': expiryYear,
          'is_default': setAsDefault,
        })
        .select()
        .single();

    return PaymentMethod.fromJson(response);
  }

  // Delete payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    await _supabase
        .from('payment_methods')
        .delete()
        .eq('id', paymentMethodId);
  }

  // Set default payment method
  Future<void> setDefaultPaymentMethod(String userId, String paymentMethodId) async {
    // Unset all defaults
    await _supabase
        .from('payment_methods')
        .update({'is_default': false})
        .eq('user_id', userId);

    // Set new default
    await _supabase
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', paymentMethodId);
  }

  // Process payment (dummy)
  Future<Map<String, dynamic>> processPayment({
    required String bookingId,
    required String userId,
    required String paymentMethodId,
    required double amount,
  }) async {
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Generate dummy transaction ID
    final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

    // Get payment method details
    final paymentMethod = await _supabase
        .from('payment_methods')
        .select()
        .eq('id', paymentMethodId)
        .single();

    // Record payment
    await _supabase.from('payments').insert({
      'booking_id': bookingId,
      'user_id': userId,
      'payment_method_id': paymentMethodId,
      'amount': amount,
      'payment_method': paymentMethod['card_type'],
      'payment_status': 'completed',
      'transaction_id': transactionId,
      'card_last4': paymentMethod['card_number_last4'],
    });

    return {
      'success': true,
      'transaction_id': transactionId,
      'amount': amount,
    };
  }

  // Helper: Validate card number (Luhn algorithm)
  bool _validateCardNumber(String cardNumber) {
    final number = cardNumber.replaceAll(' ', '');
    if (number.length < 13 || number.length > 19) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // Helper: Get card type from number
  String _getCardType(String cardNumber) {
    final number = cardNumber.replaceAll(' ', '');
    
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('3')) return 'American Express';
    if (number.startsWith('6')) return 'Discover';
    
    return 'Unknown';
  }
}