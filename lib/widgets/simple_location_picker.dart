
// ============================================
// SIMPLE LOCATION PICKER (Without Google Maps)
// ============================================
// Create new file: lib/widgets/simple_location_picker.dart

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class SimpleLocationPicker extends StatefulWidget {
  final Function(String, double, double) onLocationSelected;

  const SimpleLocationPicker({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final _searchController = TextEditingController();
  final List<Map<String, dynamic>> _popularLocations = [
    {
      'name': 'Islamabad Airport',
      'address': 'Islamabad International Airport',
      'lat': 33.6169,
      'lng': 72.9881,
      'icon': Icons.flight,
    },
    {
      'name': 'Blue Area',
      'address': 'Blue Area, Islamabad',
      'lat': 33.7077,
      'lng': 73.0492,
      'icon': Icons.business,
    },
    {
      'name': 'F-6 Markaz',
      'address': 'F-6 Markaz, Islamabad',
      'lat': 33.7215,
      'lng': 73.0433,
      'icon': Icons.shopping_bag,
    },
    {
      'name': 'Centaurus Mall',
      'address': 'Centaurus Mall, Islamabad',
      'lat': 33.7070,
      'lng': 73.0532,
      'icon': Icons.shopping_cart,
    },
    {
      'name': 'Bahria Town',
      'address': 'Bahria Town Phase 7, Rawalpindi',
      'lat': 33.5282,
      'lng': 73.1331,
      'icon': Icons.home,
    },
    {
      'name': 'Saddar Rawalpindi',
      'address': 'Saddar, Rawalpindi',
      'lat': 33.5989,
      'lng': 73.0456,
      'icon': Icons.location_city,
    },
  ];

  List<Map<String, dynamic>> _filteredLocations = [];

  @override
  void initState() {
    super.initState();
    _filteredLocations = _popularLocations;
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = _popularLocations;
      } else {
        _filteredLocations = _popularLocations
            .where((loc) =>
                loc['name']!.toLowerCase().contains(query.toLowerCase()) ||
                loc['address']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor,
            child: TextField(
              controller: _searchController,
              onChanged: _filterLocations,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Popular Locations Header
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Popular Locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Locations List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final location = _filteredLocations[index];
                return _buildLocationCard(location);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
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
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            location['icon'] as IconData,
            color: AppTheme.primaryColor,
            size: 28,
          ),
        ),
        title: Text(
          location['name'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            location['address'] as String,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: AppTheme.primaryColor,
        ),
        onTap: () {
          widget.onLocationSelected(
            location['name'] as String,
            location['lat'] as double,
            location['lng'] as double,
          );
          Navigator.pop(context, location);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
