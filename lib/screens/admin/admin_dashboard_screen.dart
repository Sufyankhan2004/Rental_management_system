// ============================================
// FILE 23: screens/admin/admin_dashboard_screen.dart
// ============================================
// Create new file: lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'manage_cars_screen.dart';
import 'manage_bookings_screen.dart';
import 'analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Cars', icon: Icon(Icons.directions_car)),
            Tab(text: 'Bookings', icon: Icon(Icons.book)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AnalyticsScreen(),
          ManageCarsScreen(),
          ManageBookingsScreen(),
        ],
      ),
    );
  }
}