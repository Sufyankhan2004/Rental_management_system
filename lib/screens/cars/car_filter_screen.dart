// ============================================
// FILE: lib/screens/cars/car_filter_screen.dart
// ============================================
// Create new file: lib/screens/cars/car_filter_screen.dart

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../utils/constants.dart';

class CarFilterScreen extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const CarFilterScreen({
    super.key,
    this.currentFilters = const {},
  });

  @override
  State<CarFilterScreen> createState() => _CarFilterScreenState();
}

class _CarFilterScreenState extends State<CarFilterScreen> {
  // Filter values
  String? _selectedType;
  String? _selectedTransmission;
  String? _selectedFuelType;
  RangeValues _priceRange = const RangeValues(0, 500);
  int _minSeats = 2;
  double _minRating = 0;
  bool _availableOnly = true;

  @override
  void initState() {
    super.initState();
    // Initialize with current filters if any
    _selectedType = widget.currentFilters['type'];
    _selectedTransmission = widget.currentFilters['transmission'];
    _selectedFuelType = widget.currentFilters['fuelType'];
    _priceRange = widget.currentFilters['priceRange'] ?? const RangeValues(0, 500);
    _minSeats = widget.currentFilters['minSeats'] ?? 2;
    _minRating = widget.currentFilters['minRating'] ?? 0;
    _availableOnly = widget.currentFilters['availableOnly'] ?? true;
  }

  void _applyFilters() {
    final filters = {
      'type': _selectedType,
      'transmission': _selectedTransmission,
      'fuelType': _selectedFuelType,
      'priceRange': _priceRange,
      'minSeats': _minSeats,
      'minRating': _minRating,
      'availableOnly': _availableOnly,
    };
    Navigator.pop(context, filters);
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedTransmission = null;
      _selectedFuelType = null;
      _priceRange = const RangeValues(0, 500);
      _minSeats = 2;
      _minRating = 0;
      _availableOnly = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Cars'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Type Filter
            const Text(
              'Car Type',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            _buildTypeFilter(),
            const SizedBox(height: 32),

            // Price Range Filter
            const Text(
              'Price Range (per day)',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            _buildPriceRangeFilter(),
            const SizedBox(height: 32),

            // Transmission Filter
            const Text(
              'Transmission',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            _buildTransmissionFilter(),
            const SizedBox(height: 32),

            // Fuel Type Filter
            const Text(
              'Fuel Type',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            _buildFuelTypeFilter(),
            const SizedBox(height: 32),

            // Seats Filter
            const Text(
              'Minimum Seats',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            _buildSeatsFilter(),
            const SizedBox(height: 32),

            // Rating Filter
            const Text(
              'Minimum Rating',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 16),
            _buildRatingFilter(),
            const SizedBox(height: 32),

            // Availability Toggle
            _buildAvailabilityToggle(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.carTypes.map((type) {
        final isSelected = _selectedType == type;
        return FilterChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (type == 'All') {
                _selectedType = null;
              } else {
                _selectedType = selected ? type : null;
              }
            });
          },
          backgroundColor: Colors.white,
          selectedColor: AppTheme.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_priceRange.start.round()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(
                'to',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                '\$${_priceRange.end.round()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 500,
            divisions: 50,
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.primaryColor.withOpacity(0.3),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransmissionFilter() {
    return Row(
      children: AppConstants.transmissionTypes.map((transmission) {
        final isSelected = _selectedTransmission == transmission;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildOptionCard(
              label: transmission,
              icon: Icons.settings,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedTransmission = isSelected ? null : transmission;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFuelTypeFilter() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppConstants.fuelTypes.map((fuelType) {
        final isSelected = _selectedFuelType == fuelType;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedFuelType = isSelected ? null : fuelType;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_gas_station,
                  size: 18,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  fuelType,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeatsFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_minSeats+',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [2, 4, 5, 7, 8].map((seats) {
              final isSelected = _minSeats == seats;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _minSeats = seats),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_seat,
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$seats',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.lightColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Minimum Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _minRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppTheme.warningColor,
            inactiveColor: AppTheme.warningColor.withOpacity(0.3),
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i <= 5; i++)
                Text(
                  '$i',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _availableOnly
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _availableOnly
                  ? AppTheme.successColor.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle,
              color: _availableOnly ? AppTheme.successColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Only',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Show only cars available for rent',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _availableOnly,
            onChanged: (value) {
              setState(() {
                _availableOnly = value;
              });
            },
            activeThumbColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}