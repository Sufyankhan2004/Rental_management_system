import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
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
              '\PKR ${car.pricePerDay.toStringAsFixed(0)}/day',
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
    Uint8List? selectedImageBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismiss
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) {
          
          // Function to pick image - defined inside builder to use correct context
          Future<void> pickImage() async {
            try {
              final ImagePicker picker = ImagePicker();
              
              // On web, directly open gallery. On mobile, show source selection
              ImageSource source = ImageSource.gallery;
              
              if (!kIsWeb) {
                final selectedSource = await showDialog<ImageSource>(
                  context: builderContext,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Select Image Source'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Gallery'),
                          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Camera'),
                          onTap: () => Navigator.pop(ctx, ImageSource.camera),
                        ),
                      ],
                    ),
                  ),
                );
                
                if (selectedSource == null) return;
                source = selectedSource;
              }

              final XFile? image = await picker.pickImage(
                source: source,
                maxWidth: 1920,
                maxHeight: 1080,
                imageQuality: 85,
              );
              
              if (image != null) {
                final bytes = await image.readAsBytes();
                setDialogState(() {
                  selectedImageBytes = bytes;
                  selectedImage = kIsWeb ? null : File(image.path);
                  imageUrlController.clear();
                });
              }
            } catch (e) {
              print('Error picking image: $e');
              if (builderContext.mounted) {
                ScaffoldMessenger.of(builderContext).showSnackBar(
                  SnackBar(
                    content: Text('Error selecting image: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            }
          }
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add New Car'),
            content: SizedBox(
              width: MediaQuery.of(builderContext).size.width * 0.8,
              child: SingleChildScrollView(
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
                    else if (selectedImageBytes != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              selectedImageBytes!,
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
                                setDialogState(() {
                                  selectedImage = null;
                                  selectedImageBytes = null;
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: pickImage,
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
                                  size: 50, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text(
                                'Add Car Image',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kIsWeb ? 'Tap to select from files' : 'Tap to select from gallery or camera',
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
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        if (nameController.text.isEmpty ||
                            brandController.text.isEmpty ||
                            priceController.text.isEmpty) {
                          ScaffoldMessenger.of(builderContext).showSnackBar(
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

                          await _carService.addCar(
                            car,
                            imageFile: selectedImage,
                            imageBytes: selectedImageBytes,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  selectedImageBytes != null
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
                          if (builderContext.mounted) {
                            ScaffoldMessenger.of(builderContext).showSnackBar(
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
                child: Text(isUploading ? 'Adding...' : 'Add Car'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditCarDialog(Car car) {
    final nameController = TextEditingController(text: car.name);
    final priceController = TextEditingController(text: car.pricePerDay.toString());
    final imageUrlController = TextEditingController(text: car.imageUrl);
    File? selectedImage;
    Uint8List? selectedImageBytes;
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
                  // Image preview/picker
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
                  else if (selectedImageBytes != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            selectedImageBytes!,
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
                              setDialogState(() {
                                selectedImage = null;
                                selectedImageBytes = null;
                              });
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
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1920,
                                maxHeight: 1080,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                final bytes = await image.readAsBytes();
                                setDialogState(() {
                                  selectedImage = kIsWeb ? null : File(image.path);
                                  selectedImageBytes = bytes;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1920,
                          maxHeight: 1080,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() {
                            selectedImage = kIsWeb ? null : File(image.path);
                            selectedImageBytes = bytes;
                          });
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
                                size: 50, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Add Car Image',
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
                    label: 'Image URL',
                    prefixIcon: Icons.link,
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
                onPressed: isUploading
                    ? null
                    : () async {
                        setDialogState(() => isUploading = true);
                        try {
                          await _carService.updateCar(
                            car.id,
                            {
                              'name': nameController.text,
                              'price_per_day': double.parse(priceController.text),
                              'image_url': imageUrlController.text.isNotEmpty
                                  ? imageUrlController.text
                                  : null,
                            },
                            newImageFile: selectedImage,
                            oldImageUrl: car.imageUrl,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Car updated successfully'),
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
                child: const Text('Update'),
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
              content: Text('Car deleted successfully'),
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