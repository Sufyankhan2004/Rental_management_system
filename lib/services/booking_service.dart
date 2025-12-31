import '../config/supabase_config.dart';
import '../models/booking_model.dart';

class BookingService {
  final _supabase = SupabaseConfig.client;

  Future<List<Booking>> getUserBookings(String userId) async {
    final response = await _supabase
        .from('bookings')
        .select('*, cars(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }

  Future<List<Booking>> getAllBookings() async {
    final response = await _supabase
        .from('bookings')
        .select('*, cars(*)')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }

  Future<Booking> createBooking(Booking booking) async {
    final response = await _supabase
        .from('bookings')
        .insert(booking.toJson())
        .select()
        .single();
    
    return Booking.fromJson(response);
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _supabase
        .from('bookings')
        .update({'status': status})
        .eq('id', id);
  }

  Future<void> cancelBooking(String id) async {
    await updateBookingStatus(id, 'cancelled');
  }

  Future<bool> isCarAvailable(String carId, DateTime from, DateTime to) async {
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('car_id', carId)
        .inFilter('status', ['confirmed', 'active'])
        .or('pickup_date.lte.${to.toIso8601String()},dropoff_date.gte.${from.toIso8601String()}');
    
    return response.isEmpty;
  }
}