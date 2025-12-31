
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:car_rental_app/services/image_picker_service.dart';
import 'package:car_rental_app/services/storage_service.dart';

import '../../config/app_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _authService = AuthService();
  final _imagePickerService = ImagePickerService();
  final _storageService = StorageService();

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isLoading = false;
  File? _profileImageFile;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // =======================
  // Load user profile
  // =======================
  Future<void> _loadProfile() async {
    try {
      final userId = _authService.userId;
      if (userId == null) return;

      final profile = await SupabaseConfig.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profile != null && mounted) {
        setState(() {
          _fullNameController.text = profile['full_name'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          _licenseController.text = profile['license_number'] ?? '';
          _profileImageUrl = profile['profile_image_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  // =======================
  // Pick profile image
  // =======================
  Future<void> _pickProfileImage() async {
    final pickedFile =
        await _imagePickerService.pickImageFromGallery();

    if (pickedFile != null && mounted) {
      setState(() {
        _profileImageFile = pickedFile;
      });
    }
  }

  // =======================
  // Save profile
  // =======================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authService.userId;
      final userEmail = _authService.userEmail;

      if (userId == null || userEmail == null) return;

      String? uploadedImageUrl = _profileImageUrl;

      if (_profileImageFile != null) {
        uploadedImageUrl = await _storageService.uploadProfileImage(_profileImageFile!, userId);
          _profileImageFile!;
          userId;
        
      }

      await SupabaseConfig.client.from('user_profiles').upsert({
        'id': userId,
        'email': userEmail,
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'license_number': _licenseController.text.trim(),
        'profile_image_url': uploadedImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                          image: _profileImageFile != null
                              ? DecorationImage(
                                  image: FileImage(_profileImageFile!),
                                  fit: BoxFit.cover,
                                )
                              : (_profileImageUrl != null &&
                                      _profileImageUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image:
                                          NetworkImage(_profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_profileImageFile == null &&
                                (_profileImageUrl == null ||
                                    _profileImageUrl!.isEmpty))
                            ? Center(
                                child: Text(
                                  _authService.userEmail
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              CustomTextField(
                controller: _fullNameController,
                label: 'Full Name',
                prefixIcon: Icons.person_outline,
                validator: Validators.validateName,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _licenseController,
                label: 'License Number',
                prefixIcon: Icons.credit_card,
                validator: Validators.validateLicenseNumber,
              ),

              const SizedBox(height: 16),

              // Email (read-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _authService.userEmail ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Verified',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }
}
