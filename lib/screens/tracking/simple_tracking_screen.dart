// ============================================
// DUMMY MAP VIEW FOR CAR TRACKING
// ============================================
// Create new file: lib/screens/tracking/simple_tracking_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/app_theme.dart';

class SimpleTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String carName;

  const SimpleTrackingScreen({
    super.key,
    required this.bookingId,
    required this.carName,
  });

  @override
  State<SimpleTrackingScreen> createState() => _SimpleTrackingScreenState();
}

class _SimpleTrackingScreenState extends State<SimpleTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _carPosition = 0.3; // 0 to 1 (pickup to dropoff)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    // Simulate car movement
    _simulateMovement();
  }

  void _simulateMovement() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _carPosition < 1.0) {
        setState(() {
          _carPosition += 0.1;
        });
        _simulateMovement();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Your Car is on the way!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.carName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ETA: ${(10 * (1 - _carPosition)).toInt()} minutes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map Area (Dummy visual)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Grid pattern (map background)
                  CustomPaint(
                    size: Size.infinite,
                    painter: MapGridPainter(),
                  ),

                  // Route line
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RoutePainter(progress: _carPosition),
                    ),
                  ),

                  // Pickup location
                  Positioned(
                    left: 40,
                    top: 80,
                    child: _buildLocationMarker(
                      'Pickup',
                      Icons.location_on,
                      AppTheme.successColor,
                    ),
                  ),

                  // Dropoff location
                  Positioned(
                    right: 40,
                    bottom: 80,
                    child: _buildLocationMarker(
                      'Dropoff',
                      Icons.flag,
                      AppTheme.errorColor,
                    ),
                  ),

                  // Moving car
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final x = 40 + (MediaQuery.of(context).size.width - 160) * _carPosition;
                      final y = 80 + (MediaQuery.of(context).size.height - 400) * _carPosition;
                      
                      return Positioned(
                        left: x,
                        top: y,
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Info Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Distance',
                    '${(5 * (1 - _carPosition)).toStringAsFixed(1)} km',
                    Icons.straighten,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    'Progress',
                    '${(_carPosition * 100).toInt()}%',
                    Icons.timeline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMarker(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for grid
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for route
class RoutePainter extends CustomPainter {
  final double progress;

  RoutePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.5)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(40, 80)
      ..lineTo(size.width - 40, size.height - 80);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) => oldDelegate.progress != progress;
}