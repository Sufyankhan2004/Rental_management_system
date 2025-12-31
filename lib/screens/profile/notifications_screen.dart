import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _authService = AuthService();
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _marketingEmails = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userId = _authService.userId;
      if (userId != null) {
        final settings = await SupabaseConfig.client
            .from('user_settings')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (settings != null) {
          setState(() {
            _emailNotifications = settings['email_notifications'] ?? true;
            _smsNotifications = settings['sms_notifications'] ?? false;
            _pushNotifications = settings['push_notifications'] ?? true;
            _marketingEmails = settings['marketing_emails'] ?? false;
            _isLoading = false;
          });
        } else {
          // Create default settings
          await _saveSettings();
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final userId = _authService.userId;
      if (userId != null) {
        await SupabaseConfig.client.from('user_settings').upsert({
          'user_id': userId,
          'email_notifications': _emailNotifications,
          'sms_notifications': _smsNotifications,
          'push_notifications': _pushNotifications,
          'marketing_emails': _marketingEmails,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Booking Notifications',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: 16),
          _buildNotificationCard(
            title: 'Email Notifications',
            subtitle: 'Receive booking updates via email',
            icon: Icons.email_outlined,
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _saveSettings();
            },
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'SMS Notifications',
            subtitle: 'Get text messages for important updates',
            icon: Icons.sms_outlined,
            value: _smsNotifications,
            onChanged: (value) {
              setState(() => _smsNotifications = value);
              _saveSettings();
            },
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            title: 'Push Notifications',
            subtitle: 'Receive app notifications',
            icon: Icons.notifications_outlined,
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveSettings();
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Marketing',
            style: AppTheme.heading3,
          ),
          const SizedBox(height: 16),
          _buildNotificationCard(
            title: 'Promotional Emails',
            subtitle: 'Receive special offers and deals',
            icon: Icons.local_offer_outlined,
            value: _marketingEmails,
            onChanged: (value) {
              setState(() => _marketingEmails = value);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
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
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }
}
