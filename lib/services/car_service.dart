// ============================================
// FILE 8: services/car_service.dart
// ============================================
// Create new file: lib/services/car_service. dart

import 'dart:typed_data';
import '../config/supabase_config.dart';
import '../models/car_model.dart';
import 'storage_service.dart';
import 'dart:io';

class CarService {
  final _supabase = SupabaseConfig.client;
  final _storageService = StorageService();

  Future<List<Car>> getAllCars() async {
    final response = await _supabase
        .from('cars')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Car.fromJson(json)).toList();
  }

  Future<List<Car>> getAvailableCars() async {
    final response = await _supabase
        .from('cars')
        .select()
        .eq('available', true)
        .order('rating', ascending: false);
    
    return (response as List).map((json) => Car.fromJson(json)).toList();
  }

  Future<Car> getCarById(String id) async {
    final response = await _supabase
        . from('cars')
        .select()
        .eq('id', id)
        .single();
    
    return Car.fromJson(response);
  }

  Future<List<Car>> searchCars({
    String? type,
    double? maxPrice,
    int? minSeats,
    String? transmission,
  }) async {
    var query = _supabase.from('cars').select().eq('available', true);

    if (type != null) query = query.eq('type', type);
    if (maxPrice != null) query = query.lte('price_per_day', maxPrice);
    if (minSeats != null) query = query.gte('seats', minSeats);
    if (transmission != null) query = query.eq('transmission', transmission);

    final response = await query;
    return (response as List).map((json) => Car.fromJson(json)).toList();
  }

  /// Add a new car with optional image upload
  /// 
  /// Parameters:
  /// - car: Car object with details
  /// - imageFile: Optional image file to upload (for mobile/desktop)
  /// - imageBytes: Optional image bytes to upload (for web)
  /// 
  /// Returns: The created car's ID
  Future<String> addCar(
    Car car, {
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      // First, insert car without image to get the ID
      final carData = car.toJson();
      carData.remove('id');  // Remove id so Supabase auto-generates UUID
      carData.remove('created_at');  // Let Supabase set this too
      carData['image_url'] = null; // Ensure image_url is null initially
      
      final response = await _supabase
          .from('cars')
          .insert(carData)
          .select()
          .single();
      
      final carId = response['id'] as String;
      
      // Upload image if provided and update car with image URL
      String? imageUrl;
      
      if (imageFile != null) {
        // Upload from File (mobile/desktop)
        try {
          imageUrl = await _storageService.uploadCarImageWithRetry(imageFile, carId);
        } catch (e) {
          print('Warning: Car created but image upload failed: $e');
        }
      } else if (imageBytes != null) {
        // Upload from Uint8List (web)
        try {
          imageUrl = await _storageService.uploadCarImageFromBytesWithRetry(
            imageBytes,
            carId,
          );
        } catch (e) {
          print('Warning: Car created but image upload failed: $e');
        }
      }
      
      // Update car with image URL if upload was successful
      if (imageUrl != null) {
        await _supabase
            .from('cars')
            .update({'image_url': imageUrl})
            .eq('id', carId);
      }
      
      return carId;
    } catch (e) {
      print('Error adding car: $e');
      rethrow;
    }
  }

  /// Update car details with optional image update
  /// 
  /// Parameters:
  /// - id: Car ID
  /// - updates: Map of fields to update
  /// - newImageFile: Optional new image file (will replace existing) - for mobile/desktop
  /// - newImageBytes: Optional new image bytes (will replace existing) - for web
  /// - oldImageUrl: URL of existing image (for deletion)
  Future<void> updateCar(
    String id,
    Map<String, dynamic> updates, {
    File? newImageFile,
    Uint8List? newImageBytes,
    String? oldImageUrl,
  }) async {
    try {
      // Upload new image if provided
      String?  newImageUrl;
      
      if (newImageFile != null) {
        // Upload from File (mobile/desktop)
        // Delete old image if exists
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _storageService.deleteCarImage(oldImageUrl);
        }
        
        newImageUrl = await _storageService.uploadCarImageWithRetry(newImageFile, id);
      } else if (newImageBytes != null) {
        // Upload from Uint8List (web)
        // Delete old image if exists
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _storageService.deleteCarImage(oldImageUrl);
        }
        
        newImageUrl = await _storageService.uploadCarImageFromBytesWithRetry(
          newImageBytes,
          id,
        );
      }
      
      if (newImageUrl != null) {
        updates['image_url'] = newImageUrl;
      }
      
      await _supabase.from('cars').update(updates).eq('id', id);
    } catch (e) {
      print('Error updating car: $e');
      rethrow;
    }
  }

  /// Delete a car and its associated images
  /// 
  /// Parameters: 
  /// - id: Car ID
  /// - imageUrl: Optional image URL to delete
  Future<void> deleteCar(String id, {String? imageUrl}) async {
    try {
      // Delete associated images from storage
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await _storageService.deleteCarImage(imageUrl);
      }
      
      // Also try to delete any orphaned images in the car's folder
      await _storageService.deleteAllCarImages(id);
      
      // Delete car from database
      await _supabase.from('cars').delete().eq('id', id);
    } catch (e) {
      print('Error deleting car: $e');
      rethrow;
    }
  }

  /// Get car image URL from storage if it exists in database
  Future<String?> getCarImageUrl(String carId) async {
    try {
      // List all files in the car's folder in storage
      final files = await SupabaseConfig.client.storage
          .from('car-images')
          .list(path: carId);
      
      if (files.isNotEmpty) {
        // Get the first image file
        final fileName = files.first.name;
        final imageUrl = _storageService.getPublicUrl('car-images/$carId/$fileName');
        print('✅ Found car image: $imageUrl');
        return imageUrl;
      }
      print('ℹ️ No images found for car: $carId');
      return null;
    } catch (e) {
      print('Error fetching car image: $e');
      return null;
    }
  }

  /// Get all cars with their images from storage
  Future<List<Car>> getAllCarsWithImages() async {
    try {
      final response = await _supabase
          .from('cars')
          .select()
          .order('created_at', ascending: false);
      
      List<Car> cars = (response as List).map((json) => Car.fromJson(json)).toList();
      
      // Fetch images from storage for each car
      for (int i = 0; i < cars.length; i++) {
        final imageUrl = await getCarImageUrl(cars[i].id);
        if (imageUrl != null) {
          // Create new car object with updated image URL
          cars[i] = Car(
            id: cars[i].id,
            name: cars[i].name,
            brand: cars[i].brand,
            type: cars[i].type,
            pricePerDay: cars[i].pricePerDay,
            imageUrl: imageUrl,
            seats: cars[i].seats,
            transmission: cars[i].transmission,
            fuelType: cars[i].fuelType,
            available: cars[i].available,
            rating: cars[i].rating,
            totalReviews: cars[i].totalReviews,
            features: cars[i].features,
            createdAt: cars[i].createdAt,
          );
        }
      }
      
      return cars;
    } catch (e) {
      print('Error getting cars with images: $e');
      rethrow;
    }
  }

  /// Get available cars with images from storage
  Future<List<Car>> getAvailableCarsWithImages() async {
    try {
      final response = await _supabase
          .from('cars')
          .select()
          .eq('available', true)
          .order('rating', ascending: false);
      
      List<Car> cars = (response as List).map((json) => Car.fromJson(json)).toList();
      
      // Fetch images from storage for each car
      for (int i = 0; i < cars.length; i++) {
        final imageUrl = await getCarImageUrl(cars[i].id);
        if (imageUrl != null) {
          cars[i] = Car(
            id: cars[i].id,
            name: cars[i].name,
            brand: cars[i].brand,
            type: cars[i].type,
            pricePerDay: cars[i].pricePerDay,
            imageUrl: imageUrl,
            seats: cars[i].seats,
            transmission: cars[i].transmission,
            fuelType: cars[i].fuelType,
            available: cars[i].available,
            rating: cars[i].rating,
            totalReviews: cars[i].totalReviews,
            features: cars[i].features,
            createdAt: cars[i].createdAt,
          );
        }
      }
      
      return cars;
    } catch (e) {
      print('Error getting available cars with images: $e');
      rethrow;
    }
  }
}