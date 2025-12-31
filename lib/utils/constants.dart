
class AppConstants {
  // App Info
  static const String appName = 'SufRide';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Premium Car Rental Service';

  // API Endpoints
  static const String apiBaseUrl = 'https://your-api-url.com/api';

  // Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyUserId = 'user_id';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';

  // Car Types
  static const List<String> carTypes = [
    'All',
    'Sedan',
    'SUV',
    'Sports',
    'Luxury',
    'Electric',
    'Hybrid',
  ];

  // Booking Status
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Payment Methods
  static const List<String> paymentMethods = [
    'Credit Card',
    'Debit Card',
    'PayPal',
    'Apple Pay',
    'Google Pay',
  ];

  // Fuel Types
  static const List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
    'CNG',
  ];

  // Transmission Types
  static const List<String> transmissionTypes = [
    'Automatic',
    'Manual',
    'Semi-Automatic',
  ];

  // Insurance Price
  static const double insurancePricePerDay = 15.0;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);

  // Image URLs (Placeholder)
  static const String defaultCarImage =
      'https://via.placeholder.com/400x300?text=Car';
  static const String defaultUserAvatar =
      'https://via.placeholder.com/150?text=User';
}
