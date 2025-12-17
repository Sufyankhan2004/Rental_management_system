// Add near the imports
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class StorageService {
  final _client = SupabaseConfig.client;
  final _bucket = SupabaseConfig.carImagesBucket;

  Future<String> uploadCarImageWithRetry(
    File imageFile,
    String carId, {
    int maxRetries = 3,
  }) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file not found: ${imageFile.path}');
    }

    // Simple extension check
    final ext = path.extension(imageFile.path).toLowerCase();
    const allowed = {'.jpg', '.jpeg', '.png', '.webp'};
    if (!allowed.contains(ext)) {
      throw Exception('Unsupported image format: $ext');
    }

    // Optional: add compression by using your ImageCompression here if desired
    final fileToUpload = imageFile;

    final base = path.basenameWithoutExtension(fileToUpload.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = 'cars/$carId/${timestamp}_$base$ext';
    final storage = _client.storage.from(_bucket);
    final contentType = _contentTypeForExtension(ext);

    int attempt = 0;
    Object? lastError;
    while (attempt < maxRetries) {
      try {
        await storage.upload(
          objectPath,
          fileToUpload,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: contentType,
          ),
        );
        return storage.getPublicUrl(objectPath);
      } catch (e) {
        lastError = e;
        attempt++;
        if (attempt >= maxRetries) break;
        await Future.delayed(Duration(milliseconds: 300 * attempt * attempt));
      }
    }
    throw Exception('Failed to upload image after $maxRetries attempts: $lastError');
  }

  Future<void> deleteCarImage(String imageUrl) async {
    final storage = _client.storage.from(_bucket);
    final pathInBucket = _extractPathFromPublicUrl(imageUrl) ?? imageUrl;
    await storage.remove([pathInBucket]);
  }

  Future<void> deleteAllCarImages(String carId) async {
    final storage = _client.storage.from(_bucket);
    final prefix = 'cars/$carId';
    final items = await storage.list(path: prefix);
    if (items.isEmpty) return;
    final paths = items.map((f) => '$prefix/${f.name}').toList();
    await storage.remove(paths);
  }

  String _contentTypeForExtension(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  String? _extractPathFromPublicUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final bucket = _bucket;

      final markerPub = '/storage/v1/object/public/$bucket/';
      final idxPub = uri.path.indexOf(markerPub);
      if (idxPub != -1) {
        final start = idxPub + markerPub.length;
        return Uri.decodeComponent(uri.path.substring(start));
      }

      final markerSign = '/storage/v1/object/sign/$bucket/';
      final idxSign = uri.path.indexOf(markerSign);
      if (idxSign != -1) {
        final start = idxSign + markerSign.length;
        return Uri.decodeComponent(uri.path.substring(start));
      }

      // If it's not a full URL, assume it's already a path
      return null;
    } catch (_) {
      return null;
    }
  }
}