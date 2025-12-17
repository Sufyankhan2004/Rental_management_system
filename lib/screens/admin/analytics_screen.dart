// ============================================
// PART 3: Updated Analytics Screen (Real Data)
// ============================================
// Replace lib/screens/admin/analytics_screen.dart

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/analytics_service.dart';
import '../../widgets/loading_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _analyticsService = AnalyticsService();
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await _analyticsService.getAnalytics();
      final activity = await _analyticsService.getRecentActivity();
      
      setState(() {
        _analytics = analytics;
        _recentActivity = activity;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading analytics...');
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Bookings',
                    '${_analytics['totalBookings'] ?? 0}',
                    Icons.book,
                    AppTheme.primaryColor,
                    '${_analytics['bookingGrowth']?.toStringAsFixed(1) ?? '0'}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Active Rentals',
                    '${_analytics['activeRentals'] ?? 0}',
                    Icons.directions_car,
                    AppTheme.accentColor,
                    '${_analytics['activeRentalsGrowth']?.toStringAsFixed(1) ?? '0'}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Revenue',
                    '\$${(_analytics['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                    Icons.attach_money,
                    AppTheme.secondaryColor,
                    '${_analytics['revenueGrowth']?.toStringAsFixed(1) ?? '0'}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Available Cars',
                    '${_analytics['availableCars'] ?? 0}',
                    Icons.check_circle,
                    AppTheme.successColor,
                    '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRecentActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
              if (change.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: change.startsWith('+') || !change.startsWith('-')
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    change.startsWith('+') || change.startsWith('-') ? change : '+$change',
                    style: TextStyle(
                      color: change.startsWith('-')
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: 16),
          if (_recentActivity.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No recent activity'),
              ),
            )
          else
            ..._recentActivity.take(5).map((activity) {
              final carName = activity['cars']?['name'] ?? 'Unknown Car';
              final userName = activity['user_profiles']?['full_name'] ?? 
                              activity['user_profiles']?['email'] ?? 'Unknown User';
              final status = activity['status'] ?? 'pending';
              final amount = (activity['total_price'] ?? 0).toString();
              final timeAgo = _getTimeAgo(activity['created_at']);
              
              return _buildActivityItem(
                _getStatusTitle(status),
                '$carName - $userName',
                timeAgo,
                _getStatusColor(status),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'New booking';
      case 'active':
        return 'Rental started';
      case 'completed':
        return 'Booking completed';
      case 'cancelled':
        return 'Booking cancelled';
      default:
        return 'New booking';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.successColor;
      case 'active':
        return AppTheme.primaryColor;
      case 'completed':
        return AppTheme.accentColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.warningColor;
    }
  }

  String _getTimeAgo(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

