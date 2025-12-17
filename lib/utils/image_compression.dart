// ============================================
// Image Compression Utilities
// ============================================
// Utilities for compressing and resizing images before upload

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class ImageCompression {
  // Maximum dimensions for car images (maintains aspect ratio)
  static const int maxWidth = 800;
  static const int maxHeight = 600;
  
  // JPEG quality (0-100)
  static const int jpegQuality = 85;
  
  // Maximum file size before compression (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  
  // Target file size after compression (1MB)
  static const int targetFileSizeBytes = 1024 * 1024;

  /// Compress and resize an image file
  /// Returns a new compressed file or the original if compression fails
  static Future<File> compressImage(File file) async {
    try {
      // Read the image file
      final bytes = await file.readAsBytes();
      
      // Check file size
      if (bytes.length > maxFileSizeBytes) {
        throw Exception('File size exceeds 5MB limit');
      }
      
      // Decode the image
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Unable to decode image');
      }
      
      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;
      
      if (image.width > maxWidth || image.height > maxHeight) {
        final aspectRatio = image.width / image.height;
        
        if (aspectRatio > 1) {
          // Landscape
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // Portrait
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
        
        // Resize the image
        image = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }
      
      // Encode as JPEG with quality setting
      final compressedBytes = img.encodeJpg(image, quality: jpegQuality);
      
      // Create a new file with compressed data
      final directory = file.parent;
      final fileName = path.basenameWithoutExtension(file.path);
      final compressedFile = File('${directory.path}/${fileName}_compressed.jpg');
      
      await compressedFile.writeAsBytes(compressedBytes);
      
      // Log compression results
      final originalSize = bytes.length;
      final compressedSize = compressedBytes.length;
      final reductionPercent = ((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1);
      
      print('Image compressed:');
      print('  Original: ${_formatFileSize(originalSize)}');
      print('  Compressed: ${_formatFileSize(compressedSize)}');
      print('  Reduction: $reductionPercent%');
      print('  Dimensions: ${image.width}x${image.height}');
      
      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      // Return original file if compression fails
      return file;
    }
  }

  /// Validate image file format
  static bool isValidImageFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.jpg' || 
           extension == '.jpeg' || 
           extension == '.png';
  }

  /// Format file size for display
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get formatted file size for a file
  static Future<String> getFileSize(File file) async {
    final bytes = await file.length();
    return _formatFileSize(bytes);
  }

  /// Check if file size is within limits
  static Future<bool> isFileSizeValid(File file) async {
    final bytes = await file.length();
    return bytes <= maxFileSizeBytes;
  }
}
