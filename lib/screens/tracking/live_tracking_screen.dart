// ============================================
// PART 5: Live Car Tracking Map
// ============================================
// Create new file: lib/screens/tracking/live_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/supabase_config.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;

  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentCarLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
    _startLocationUpdates();
  }

  Future<void> _loadTrackingData() async {
    try {
      final booking = await SupabaseConfig.client
          .from('bookings')
          .select('*, cars(*)')
          .eq('id', widget.bookingId)
          .single();

      setState(() {
        if (booking['current_latitude'] != null && booking['current_longitude'] != null) {
          _currentCarLocation = LatLng(
            booking['current_latitude'].toDouble(),
            booking['current_longitude'].toDouble(),
          );
        }
        
        if (booking['pickup_latitude'] != null && booking['pickup_longitude'] != null) {
          _pickupLocation = LatLng(
            booking['pickup_latitude'].toDouble(),
            booking['pickup_longitude'].toDouble(),
          );
        }
        
        if (booking['dropoff_latitude'] != null && booking['dropoff_longitude'] != null) {
          _dropoffLocation = LatLng(
            booking['dropoff_latitude'].toDouble(),
            booking['dropoff_longitude'].toDouble(),
          );
        }
        
        _updateMarkers();
      });
        } catch (e) {
      print('Error loading tracking data: $e');
    }
  }

  void _startLocationUpdates() {
    // Update location every 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _loadTrackingData();
        _startLocationUpdates();
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();

    if (_currentCarLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('car'),
          position: _currentCarLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Car'),
        ),
      );
    }

    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    if (_dropoffLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoffLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Dropoff Location'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
      ),
      body: _currentCarLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentCarLocation!,
                zoom: 14,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}