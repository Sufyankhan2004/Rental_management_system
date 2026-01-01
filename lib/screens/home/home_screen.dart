import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'search_screen.dart';
import '../booking/booking_history_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _selectedIndex = 0;
  String? _profileImageUrl;
  final _authService = AuthService();

  final List<Widget> _screens = [
    const SearchScreen(),
    const BookingHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final userId = _authService.userId;
    if (userId == null) return;
    final profile = await SupabaseConfig.client
        .from('user_profiles')
        .select('profile_image_url')
        .eq('id', userId)
        .maybeSingle();
    if (profile != null && mounted) {
      setState(() {
        _profileImageUrl = profile['profile_image_url'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF8EE3EF);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF141628),
                  Color(0xFF1B1F3A),
                  Color(0xFF090F1A),
                ],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -10,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          // Main content with padding and animation
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: Padding(
                key: ValueKey(_selectedIndex),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x331C233A),
                          Color(0x332A3763),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF232844),
                  Color(0xFF1B1F34),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              backgroundBlendMode: BlendMode.overlay,
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: accent,
              unselectedItemColor: Colors.white70,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  activeIcon: Icon(Icons.search_rounded, size: 28),
                  label: 'Explore',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_rounded),
                  activeIcon: Icon(Icons.calendar_today_rounded, size: 28),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 14,
                          backgroundImage: NetworkImage(_profileImageUrl!),
                          backgroundColor: Colors.white,
                        )
                      : const Icon(Icons.person_rounded),
                  activeIcon: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(_profileImageUrl!),
                          backgroundColor: Colors.white,
                        )
                      : const Icon(Icons.person_rounded, size: 28),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}