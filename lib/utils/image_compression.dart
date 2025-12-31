import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompression {
  // 5 MB limit (used in StorageService)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  // JPEG and PNG are supported
  static bool isValidImageFormat(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return ext == '.jpg' || ext == '.jpeg' || ext == '.png';
  }

  static Future<bool> isFileSizeValid(File file) async {
    final bytes = await file.length();
    return bytes <= maxFileSizeBytes;
  }

  // Compress image files; returns the compressed file if smaller and under limit,
  // otherwise returns the original file.
  static Future<File> compressImage(File file) async {
    try {
      // Skip compression on web; StorageService has a bytes-based path for web.
      if (kIsWeb) return file;

      final originalSize = await file.length();
      if (originalSize <= 600 * 1024) {
        // Already small enough; skip to save time and quality
        return file;
      }

      final ext = p.extension(file.path).toLowerCase();
      final isPng = ext == '.png';
      final base = p.basenameWithoutExtension(file.path);
      final dir = file.parent.path;

      final targetPath = p.join(dir, '${base}_compressed${ext.isNotEmpty ? ext : '.jpg'}');

      // First pass compression
      final first = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: isPng ? 90 : 85,
        format: isPng ? CompressFormat.png : CompressFormat.jpeg,
        keepExif: false,
        autoCorrectionAngle: true,
        minWidth: 1920,
        minHeight: 1920,
      );

      if (first == null) return file;

      final firstFile = File(first.path);
      final firstSize = await firstFile.length();

      if (firstSize <= maxFileSizeBytes && firstSize < originalSize) {
        return firstFile;
      }

      // Try more aggressive JPEG compression if needed
      if (!isPng) {
        for (final q in [75, 65, 55]) {
          final altPath = p.join(dir, '${base}_q$q.jpg');
          final alt = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            altPath,
            quality: q,
            format: CompressFormat.jpeg,
            keepExif: false,
            autoCorrectionAngle: true,
            minWidth: 1920,
            minHeight: 1920,
          );
          if (alt == null) continue;

          final altFile = File(alt.path);
          final altSize = await altFile.length();
          if (altSize <= maxFileSizeBytes && altSize < originalSize) {
            // Clean up the previous attempt if different
            if (firstFile.path != altFile.path && await firstFile.exists()) {
              try { await firstFile.delete(); } catch (_) {}
            }
            return altFile;
          } else {
            try { await altFile.delete(); } catch (_) {}
          }
        }
      }

      // Clean up and return original if compression didn't help
      try { await firstFile.delete(); } catch (_) {}
      return file;
    } catch (_) {
      // On any error, return the original file to avoid blocking uploads
      return file;
    }
  }
}