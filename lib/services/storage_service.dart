import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../config/supabase_config.dart';
import '../utils/image_compression.dart';

class StorageService {
  final _supabase = SupabaseConfig.client;
 
Future<String> uploadProfileImage(File file, String userId) async {
  try {
    // Validate format
    if (!ImageCompression.isValidImageFormat(file.path)) {
      throw Exception('Invalid image format.');
    }

    // Validate size
    if (!await ImageCompression.isFileSizeValid(file)) {
      throw Exception('Image exceeds size limit.');
    }

    // Compress image
    final compressedFile = await ImageCompression.compressImage(file);

    // File path: profiles/{userId}.jpg
    final filePath = 'profiles/$userId.jpg';

    await _supabase.storage.from('profile-images').upload(
      filePath,
      compressedFile,
      fileOptions: const FileOptions(
        upsert: true,
        cacheControl: '3600',
      ),
    );

    return _supabase.storage
        .from('profile-images')
        .getPublicUrl(filePath);
  } catch (e) {
    rethrow;
  }
}

  
  // Bucket name for car images
  static const String bucketName = 'car-images';
  
  // UUID generator for unique filenames
  final _uuid = const Uuid();

 
  Future<String> uploadCarImage(File file, String carId) async {
    try {
      // Validate file format
      if (!ImageCompression.isValidImageFormat(file.path)) {
        throw Exception('Invalid file format. Only JPEG and PNG are supported.');
      }

      // Validate file size
      if (!await ImageCompression.isFileSizeValid(file)) {
        throw Exception('File size exceeds 5MB limit.');
      }

      // Compress the image
      print('Compressing image...');
      final compressedFile = await ImageCompression.compressImage(file);

      // Generate unique filename
      final fileName = _generateUniqueFileName(carId, path.extension(compressedFile.path));
      final filePath = '$carId/$fileName';

      // Upload to Supabase Storage
      print('Uploading to Supabase Storage...');
      await _supabase.storage.from(bucketName).upload(
        filePath,
        compressedFile,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);

      // Clean up compressed file if it's different from original
      if (compressedFile.path != file.path) {
        try {
          await compressedFile.delete();
        } catch (e) {
          print('Warning: Could not delete temporary compressed file at ${compressedFile.path}: $e');
        }
      }

      print('Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload an image to Supabase Storage from Uint8List (for web)
  /// 
  /// Parameters:
  /// - imageBytes: The image data as bytes
  /// - carId: The ID of the car (used in file path)
  /// - fileName: Optional original filename (defaults to generated name)
  /// 
  /// Returns: Public URL of the uploaded image
  /// 
  /// Throws: Exception if upload fails
  Future<String> uploadCarImageFromBytes(
    Uint8List imageBytes,
    String carId, {
    String? fileName,
  }) async {
    try {
      // Validate file size
      if (imageBytes.length > ImageCompression.maxFileSizeBytes) {
        throw Exception('File size exceeds 5MB limit.');
      }

      // Generate unique filename
      final uniqueFileName = _generateUniqueFileName(carId, '.jpg');
      final filePath = '$carId/$uniqueFileName';

      // Upload to Supabase Storage
      print('Uploading to Supabase Storage (from bytes)...');
      await _supabase.storage.from(bucketName).uploadBinary(
        filePath,
        imageBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);

      print('Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image from bytes: $e');
      rethrow;
    }
  }

  /// Upload an image with retry logic (File version)
  /// 
  /// Retries upload up to maxRetries times with exponential backoff
  Future<String> uploadCarImageWithRetry(
    File file,
    String carId, {
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Duration delay = const Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        return await uploadCarImage(file, carId);
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('Upload failed after $maxRetries attempts: $e');
        }
        
        print('Upload attempt $retryCount failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    throw Exception('Upload failed after $maxRetries attempts');
  }

  /// Upload an image with retry logic (Uint8List version for web)
  /// 
  /// Retries upload up to maxRetries times with exponential backoff
  Future<String> uploadCarImageFromBytesWithRetry(
    Uint8List imageBytes,
    String carId, {
    String? fileName,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Duration delay = const Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        return await uploadCarImageFromBytes(imageBytes, carId, fileName: fileName);
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception('Upload failed after $maxRetries attempts: $e');
        }
        
        print('Upload attempt $retryCount failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    throw Exception('Upload failed after $maxRetries attempts');
  }

  /// Delete an image from Supabase Storage
  /// 
  /// Parameters:
  /// - imageUrl: The public URL of the image to delete
  /// 
  /// Returns: true if deletion was successful, false otherwise
  Future<bool> deleteCarImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final filePath = _extractFilePathFromUrl(imageUrl);
      if (filePath == null) {
        print('Could not extract file path from URL: $imageUrl');
        return false;
      }

      // Delete from storage
      await _supabase.storage.from(bucketName).remove([filePath]);
      
      print('Image deleted: $filePath');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Delete all images for a specific car
  /// 
  /// Parameters:
  /// - carId: The ID of the car
  /// 
  /// Returns: Number of images deleted
  Future<int> deleteAllCarImages(String carId) async {
    try {
      // List all files in the car's folder
      final files = await _supabase.storage.from(bucketName).list(path: carId);
      
      if (files.isEmpty) {
        return 0;
      }

      // Build file paths
      final filePaths = files.map((file) => '$carId/${file.name}').toList();

      // Delete all files
      await _supabase.storage.from(bucketName).remove(filePaths);
      
      print('Deleted ${files.length} images for car $carId');
      return files.length;
    } catch (e) {
      print('Error deleting car images: $e');
      return 0;
    }
  }

  /// Generate a unique filename for car images
  /// 
  /// Format: {timestamp}_{uuid}.{extension}
  /// Example: 1234567890_a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg
  String _generateUniqueFileName(String carId, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _uuid.v4(); // Use full UUID for better uniqueness
    
    // Remove leading dot from extension if present
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    
    // Always use .jpg for consistency
    return '${timestamp}_$uuid.jpg';
  }

  /// Extract file path from Supabase Storage public URL
  /// 
  /// Example: 
  /// Input: https://xxx.supabase.co/storage/v1/object/public/car-images/car123/file.jpg
  /// Output: car123/file.jpg
  String? _extractFilePathFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the bucket name in the path
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        return null;
      }
      
      // Get everything after the bucket name
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      return filePath;
    } catch (e) {
      print('Error extracting file path: $e');
      return null;
    }
  }

  /// Check if the storage bucket exists and is accessible
  Future<bool> checkBucketExists() async {
    try {
      await _supabase.storage.from(bucketName).list(path: '');
      return true;
    } catch (e) {
      print('Bucket check failed: $e');
      return false;
    }
  }

  /// Get the public URL for a file path
  String getPublicUrl(String filePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
  }
}