import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign In
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      print('🔐 Attempting sign in for: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in successful: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      print('   Status code: ${e.statusCode}');
      throw Exception(e.message);
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    }
  }

  // Sign Up - FIXED for 404 error
  Future<AuthResponse> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      print('📝 Attempting sign up for: $email');
      print('   Full name: $fullName');
      
      // Sign up the user
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: null, // Important: Set to null for now
      );

      print('✅ Sign up response received');
      print('   User ID: ${response.user?.id}');
      print('   Email: ${response.user?.email}');

      // Only create profile if user was successfully created
      if (response.user != null) {
        // Small delay to ensure auth user is created
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          // Check if profile already exists
          final existingProfile = await _supabase
              .from('user_profiles')
              .select()
              .eq('id', response.user!.id)
              .maybeSingle();
          
          if (existingProfile == null) {
            // Create new profile
            await _supabase.from('user_profiles').upsert({
              'id': response.user!.id,
              'email': email,
              'full_name': fullName,
              'profile_image_url': null,
            },
            onConflict: 'id');
            print('✅ User profile created');
          } else {
            print('ℹ️ Profile already exists');
          }
        } catch (profileError) {
          // Profile creation failed, but user was created
          print('⚠️ Profile creation failed: $profileError');
          // Don't throw error - user account still works
        }
      }

      return response;
    } on AuthException catch (e) {
      print('❌ Auth exception: ${e.message}');
      print('   Status code: ${e.statusCode}');
      
      // Provide user-friendly error messages
      if (e.statusCode == '404') {
        throw Exception(
          'Service not available. Please check your Supabase configuration.',
        );
      } else if (e.message.contains('already registered')) {
        throw Exception('This email is already registered');
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      print('❌ Sign up error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow;
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      print('✅ Password reset email sent');
    } catch (e) {
      print('❌ Password reset error: $e');
      rethrow;
    }
  }

  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.id;
  String? get userEmail => currentUser?.email;
}
