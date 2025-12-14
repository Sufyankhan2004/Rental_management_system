// ============================================
// PART 2: Payment Models
// ============================================
// Create new file: lib/models/payment_method_model.dart

class PaymentMethod {
  final String id;
  final String userId;
  final String cardHolderName;
  final String cardNumberLast4;
  final String cardType; // Visa, Mastercard, etc.
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.cardHolderName,
    required this.cardNumberLast4,
    required this.cardType,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      cardHolderName: json['card_holder_name'] ?? '',
      cardNumberLast4: json['card_number_last4'] ?? '',
      cardType: json['card_type'] ?? '',
      expiryMonth: json['expiry_month'] ?? 1,
      expiryYear: json['expiry_year'] ?? 2024,
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'card_holder_name': cardHolderName,
      'card_number_last4': cardNumberLast4,
      'card_type': cardType,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get maskedCardNumber => '**** **** **** $cardNumberLast4';
  String get expiryDate => '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';
}