// ============================================
// FILE 8: services/car_service.dart
// ============================================
// Create new file: lib/services/car_service.dart

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
        .from('cars')
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
  /// - imageFile: Optional image file to upload
  /// 
  /// Returns: The created car's ID
  Future<String> addCar(Car car, {File? imageFile}) async {
    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        // Generate temporary ID for upload path
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await _storageService.uploadCarImageWithRetry(imageFile, tempId);
      }
      
      // Prepare car data with image URL
      final carData = car.toJson();
      if (imageUrl != null) {
        carData['image_url'] = imageUrl;
      }
      
      // Insert car and get the ID
      final response = await _supabase
          .from('cars')
          .insert(carData)
          .select()
          .single();
      
      return response['id'] as String;
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
  /// - newImageFile: Optional new image file (will replace existing)
  /// - oldImageUrl: URL of existing image (for deletion)
  Future<void> updateCar(
    String id,
    Map<String, dynamic> updates, {
    File? newImageFile,
    String? oldImageUrl,
  }) async {
    try {
      // Upload new image if provided
      if (newImageFile != null) {
        // Delete old image if exists
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await _storageService.deleteCarImage(oldImageUrl);
        }
        
        // Upload new image
        final newImageUrl = await _storageService.uploadCarImageWithRetry(newImageFile, id);
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
}