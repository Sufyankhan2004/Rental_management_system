// ============================================
// UPDATED: lib/screens/admin/manage_cars_screen.dart
// ============================================
// Add image upload functionality to your admin screen

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/app_theme.dart';
import '../../models/car_model.dart';
import '../../services/car_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';

class ManageCarsScreen extends StatefulWidget {
  const ManageCarsScreen({super.key});

  @override
  State<ManageCarsScreen> createState() => _ManageCarsScreenState();
}

class _ManageCarsScreenState extends State<ManageCarsScreen> {
  final _carService = CarService();
  List<Car> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() => _isLoading = true);
    try {
      final cars = await _carService.getAllCars();
      setState(() {
        _cars = cars;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cars: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget(message: 'Loading cars...')
          : _cars.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCars,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cars.length,
                    itemBuilder: (context, index) {
                      return _buildCarCard(_cars[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCarDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Car'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          const Text(
            'No Cars Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first car to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddCarDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Car'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Car car) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Car image preview
          if (car.imageUrl != null && car.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                car.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              ),
            ),
          
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            title: Text(
              car.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${car.brand} • ${car.type}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: AppTheme.warningColor),
                    const SizedBox(width: 4),
                    Text('${car.rating}'),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: car.available ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      car.available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color: car.available ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '\$${car.pricePerDay.toStringAsFixed(0)}/day',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditCarDialog(car),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleAvailability(car),
                    icon: Icon(
                      car.available ? Icons.close : Icons.check,
                      size: 18,
                    ),
                    label: Text(car.available ? 'Disable' : 'Enable'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: car.available
                          ? AppTheme.warningColor
                          : AppTheme.successColor,
                      side: BorderSide(
                        color: car.available
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _deleteCar(car),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Icon(Icons.delete, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCarDialog() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final typeController = TextEditingController();
    final priceController = TextEditingController();
    final seatsController = TextEditingController(text: '4');
    final transmissionController = TextEditingController(text: 'Automatic');
    final fuelTypeController = TextEditingController(text: 'Petrol');
    final imageUrlController = TextEditingController();
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add New Car'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker with upload indicator
                  if (isUploading)
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Uploading image...'),
                        ],
                      ),
                    )
                  else if (selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () {
                              setDialogState(() => selectedImage = null);
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: () async {
                        // Show image source selection
                        final ImageSource? source = await showDialog<ImageSource>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Image Source'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Gallery'),
                                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Camera'),
                                  onTap: () => Navigator.pop(context, ImageSource.camera),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (source != null) {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: source,
                            maxWidth: 1920,
                            maxHeight: 1080,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = File(image.path);
                              // Clear URL field since image file and URL are mutually exclusive
                              imageUrlController.clear();
                            });
                          }
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, 
                                size: 50, 
                                color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Add Car Image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to select from gallery or camera',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('OR', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: imageUrlController,
                    label: 'Image URL',
                    prefixIcon: Icons.link,
                    enabled: selectedImage == null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: nameController,
                    label: 'Car Name',
                    prefixIcon: Icons.directions_car,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: brandController,
                    label: 'Brand',
                    prefixIcon: Icons.business,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: typeController,
                    label: 'Type (e.g., SUV, Sedan)',
                    prefixIcon: Icons.category,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: priceController,
                    label: 'Price per Day',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: seatsController,
                    label: 'Number of Seats',
                    prefixIcon: Icons.event_seat,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: transmissionController,
                    label: 'Transmission',
                    prefixIcon: Icons.settings,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: fuelTypeController,
                    label: 'Fuel Type',
                    prefixIcon: Icons.local_gas_station,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (nameController.text.isEmpty ||
                      brandController.text.isEmpty ||
                      priceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all required fields'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                    return;
                  }

                  setDialogState(() => isUploading = true);

                  try {
                    String? imageUrl = imageUrlController.text.isNotEmpty 
                        ? imageUrlController.text 
                        : null;

                    final car = Car(
                      id: '',
                      name: nameController.text,
                      brand: brandController.text,
                      type: typeController.text,
                      pricePerDay: double.parse(priceController.text),
                      imageUrl: imageUrl,
                      seats: int.tryParse(seatsController.text) ?? 4,
                      transmission: transmissionController.text,
                      fuelType: fuelTypeController.text,
                      available: true,
                      features: ['Air Conditioning', 'Bluetooth', 'GPS'],
                      createdAt: DateTime.now(),
                    );

                    // Add car with image upload
                    await _carService.addCar(car, imageFile: selectedImage);
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            selectedImage != null
                                ? 'Car added with image successfully'
                                : 'Car added successfully',
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      _loadCars();
                    }
                  } catch (e) {
                    setDialogState(() => isUploading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Add Car'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCarDialog(Car car) {
    final nameController = TextEditingController(text: car.name);
    final priceController = TextEditingController(
      text: car.pricePerDay.toString(),
    );
    final imageUrlController = TextEditingController(text: car.imageUrl);
    File? newImageFile;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Car'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current or new image preview
                  if (isUploading)
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Uploading image...'),
                        ],
                      ),
                    )
                  else if (newImageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            newImageFile!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () {
                              setDialogState(() => newImageFile = null);
                            },
                          ),
                        ),
                      ],
                    )
                  else if (car.imageUrl != null && car.imageUrl!.isNotEmpty)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            car.imageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () async {
                              final ImageSource? source = await showDialog<ImageSource>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Select Image Source'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
                                        title: const Text('Gallery'),
                                        onTap: () => Navigator.pop(context, ImageSource.gallery),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text('Camera'),
                                        onTap: () => Navigator.pop(context, ImageSource.camera),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (source != null) {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                  source: source,
                                  maxWidth: 1920,
                                  maxHeight: 1080,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setDialogState(() {
                                    newImageFile = File(image.path);
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: () async {
                        final ImageSource? source = await showDialog<ImageSource>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Image Source'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Gallery'),
                                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Camera'),
                                  onTap: () => Navigator.pop(context, ImageSource.camera),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (source != null) {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: source,
                            maxWidth: 1920,
                            maxHeight: 1080,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            setDialogState(() {
                              newImageFile = File(image.path);
                            });
                          }
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, 
                                size: 50, 
                                color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Add Image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: nameController,
                    label: 'Car Name',
                    prefixIcon: Icons.directions_car,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: priceController,
                    label: 'Price per Day',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: imageUrlController,
                    label: 'Image URL (optional)',
                    prefixIcon: Icons.link,
                    enabled: newImageFile == null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  setDialogState(() => isUploading = true);

                  try {
                    final updates = {
                      'name': nameController.text,
                      'price_per_day': double.parse(priceController.text),
                    };

                    // Only update URL if no new image file is selected
                    if (newImageFile == null && imageUrlController.text.isNotEmpty) {
                      updates['image_url'] = imageUrlController.text;
                    }

                    await _carService.updateCar(
                      car.id,
                      updates,
                      newImageFile: newImageFile,
                      oldImageUrl: car.imageUrl,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newImageFile != null
                                ? 'Car updated with new image'
                                : 'Car updated successfully',
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      _loadCars();
                    }
                  } catch (e) {
                    setDialogState(() => isUploading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleAvailability(Car car) async {
    try {
      await _carService.updateCar(car.id, {'available': !car.available});
      _loadCars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Car ${car.available ? 'disabled' : 'enabled'} successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteCar(Car car) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Car'),
        content: Text('Are you sure you want to delete ${car.name}?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _carService.deleteCar(car.id, imageUrl: car.imageUrl);
        _loadCars();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Car and associated images deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}