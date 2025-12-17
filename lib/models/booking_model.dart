// ============================================
// FILE 5: models/booking_model.dart
// ============================================
// Create new file: lib/models/booking_model.dart

import 'package:car_rental_app/models/car_model.dart';

class Booking {
  final String id;
  final String userId;
  final String carId;
  final DateTime pickupDate;
  final DateTime dropoffDate;
  final String pickupLocation;
  final String dropoffLocation;
  final double totalPrice;
  final String status;
  final bool insuranceIncluded;
  final DateTime createdAt;
  final Car? car;

  Booking({
    required this.id,
    required this.userId,
    required this.carId,
    required this.pickupDate,
    required this.dropoffDate,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.totalPrice,
    required this.status,
    this.insuranceIncluded = false,
    required this.createdAt,
    this.car,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      carId: json['car_id'] ?? '',
      pickupDate: DateTime.parse(json['pickup_date']),
      dropoffDate: DateTime.parse(json['dropoff_date']),
      pickupLocation: json['pickup_location'] ?? '',
      dropoffLocation: json['dropoff_location'] ?? '',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      insuranceIncluded: json['insurance_included'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      car: json['cars'] != null ? Car.fromJson(json['cars']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'user_id': userId,
      'car_id': carId,
      'pickup_date': pickupDate.toIso8601String(),
      'dropoff_date': dropoffDate.toIso8601String(),
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'total_price': totalPrice,
      'status': status,
      'insurance_included': insuranceIncluded,
      'created_at': createdAt.toIso8601String(),
    };
    
    // Only include id if it's not empty (for updates)
    if (id.isNotEmpty) {
      json['id'] = id;
    }
    
    return json;
  }

  int get durationInDays {
    return dropoffDate.difference(pickupDate).inDays;
  }
}