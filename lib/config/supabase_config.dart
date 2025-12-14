// ============================================
// SOLUTION FOR 404 ERROR
// ============================================
// Replace your lib/config/supabase_config.dart with this:

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // CRITICAL: Your URL must be EXACTLY like this format
  // Example: 'https://abcdefghijk.supabase.co'
  // NO trailing slash, NO /auth/v1 at the end
  static const String supabaseUrl = 'https://avnautrznpmublifaoox.supabase.co';
  
  // Example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2bmF1dHJ6bnBtdWJsaWZhb294Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MTE3NTIsImV4cCI6MjA4MTA4Nzc1Mn0.K_fwTLx8J9rVJYvMtLd-0lESvTx9zDVASHCTicq1zYo';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        // Add these options to help with debugging
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      print('✅ Supabase initialized successfully');
      print('   URL: $supabaseUrl');
    } catch (e) {
      print('❌ Supabase initialization error: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
