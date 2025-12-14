// ============================================
// FILE 8: services/car_service.dart
// ============================================
// Create new file: lib/services/car_service.dart

import '../config/supabase_config.dart';
import '../models/car_model.dart';

class CarService {
  final _supabase = SupabaseConfig.client;

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

  Future<void> addCar(Car car) async {
    await _supabase.from('cars').insert(car.toJson());
  }

  Future<void> updateCar(String id, Map<String, dynamic> updates) async {
    await _supabase.from('cars').update(updates).eq('id', id);
  }

  Future<void> deleteCar(String id) async {
    await _supabase.from('cars').delete().eq('id', id);
  }
}