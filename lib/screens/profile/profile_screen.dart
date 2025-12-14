// ============================================
// PART 7: UPDATED Profile Screen with Working Buttons
// ============================================
// Replace your existing lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../admin/admin_dashboard_screen.dart';
import 'edit_profile_screen.dart';
import 'payment_methods_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _bookingService = BookingService();
  final _authService = AuthService();
  int _totalTrips = 0;
  double _totalSpent = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final userId = _authService.userId;
      if (userId != null) {
        final bookings = await _bookingService.getUserBookings(userId);
        
        // Count total trips (confirmed, completed, or active bookings)
        // This includes all bookings the user has made or is currently using
        final completedBookings = bookings.where(
          (booking) => booking.status == 'confirmed' || 
                      booking.status == 'completed' ||
                      booking.status == 'active'
        ).toList();
        
        // Calculate total spent from only completed bookings for financial accuracy
        // Only completed bookings represent finalized transactions
        final totalSpent = bookings.where(
          (booking) => booking.status == 'completed'
        ).fold<double>(
          0.0,
          (sum, booking) => sum + booking.totalPrice,
        );
        
        setState(() {
          _totalTrips = completedBookings.length;
          _totalSpent = totalSpent;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFF5A52D5),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.email?.split('@')[0] ?? 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Premium Member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          _isLoading ? '...' : '$_totalTrips',
                          'Total Trips',
                          Icons.directions_car,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          _isLoading ? '...' : '\$${_totalSpent.toStringAsFixed(0)}',
                          'Total Spent',
                          Icons.attach_money,
                          AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Menu Options - ALL WORKING NOW!
                  _buildMenuOption(
                    context,
                    Icons.person_outline,
                    'Edit Profile',
                    () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                      // Refresh stats if profile was updated
                      if (result == true) {
                        _loadUserStats();
                      }
                    },
                  ),
                  _buildMenuOption(
                    context,
                    Icons.credit_card_outlined,
                    'Payment Methods',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuOption(
                    context,
                    Icons.notifications_outlined,
                    'Notifications',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuOption(
                    context,
                    Icons.admin_panel_settings_outlined,
                    'Admin Panel',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuOption(
                    context,
                    Icons.help_outline,
                    'Help & Support',
                    () {
                      _showHelpDialog(context);
                    },
                  ),
                  _buildMenuOption(
                    context,
                    Icons.info_outline,
                    'About',
                    () {
                      _showAboutDialog(context);
                    },
                  ),
                  _buildMenuOption(
                    context,
                    Icons.logout,
                    'Logout',
                    () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await AuthService().signOut();
                      }
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDestructive ? AppTheme.errorColor : AppTheme.primaryColor)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppTheme.errorColor : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Help & Support'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.email, color: AppTheme.primaryColor),
              title: Text('Email'),
              subtitle: Text('support@luxride.com'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.phone, color: AppTheme.primaryColor),
              title: Text('Phone'),
              subtitle: Text('+1 (555) 123-4567'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.access_time, color: AppTheme.primaryColor),
              title: Text('Hours'),
              subtitle: Text('Mon-Fri: 9AM-6PM'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('About LuxRide'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LuxRide Car Rental',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Your premium car rental service. Book luxury and economy vehicles with ease.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 LuxRide. All rights reserved.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}