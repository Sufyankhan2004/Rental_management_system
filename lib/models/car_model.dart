// ============================================
// FILE 4: models/car_model.dart
// ============================================
// Create new file: lib/models/car_model.dart

class Car {
  final String id;
  final String name;
  final String brand;
  final String type;
  final double pricePerDay;
  final String? imageUrl;
  final int seats;
  final String transmission;
  final String fuelType;
  final bool available;
  final double rating;
  final int totalReviews;
  final List<String> features;
  final DateTime createdAt;

  Car({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
    required this.pricePerDay,
    this.imageUrl,
    required this.seats,
    required this.transmission,
    required this.fuelType,
    required this.available,
    this.rating = 4.5,
    this.totalReviews = 0,
    this.features = const [],
    required this.createdAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      type: json['type'] ?? '',
      pricePerDay: (json['price_per_day'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      seats: json['seats'] ?? 4,
      transmission: json['transmission'] ?? 'Automatic',
      fuelType: json['fuel_type'] ?? 'Petrol',
      available: json['available'] ?? true,
      rating: (json['rating'] ?? 4.5).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'type': type,
      'price_per_day': pricePerDay,
      'image_url': imageUrl,
      'seats': seats,
      'transmission': transmission,
      'fuel_type': fuelType,
      'available': available,
      'rating': rating,
      'total_reviews': totalReviews,
      'features': features,
      'created_at': createdAt.toIso8601String(),
    };
  }
}