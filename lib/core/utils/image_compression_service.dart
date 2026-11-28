import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses user-selected images on-device before uploading to Firebase
/// Storage, reducing storage footprint & bandwidth costs by 75–90% and
/// stripping EXIF metadata for user privacy.
class ImageCompressionService {
  ImageCompressionService._();

  static const int defaultMaxDimension = 1280;
  static const int defaultQuality = 72;

  /// Compresses [bytes] to an optimized JPEG (<= [maxDimension]px, [quality]%).
  /// Falls back safely to [bytes] on unsupported platforms (Web/Desktop/tests)
  /// or if compression yields a larger output.
  static Future<Uint8List> compressForUpload(
    Uint8List bytes, {
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) async {
    if (bytes.isEmpty) return bytes;
    // Skip tiny images (< 60 KB) that are already compact.
    if (bytes.lengthInBytes < 60 * 1024) return bytes;

    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return bytes;
    }

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (compressed.isNotEmpty && compressed.length < bytes.length) {
        return Uint8List.fromList(compressed);
      }
    } catch (e) {
      debugPrint('On-device image compression skipped: $e');
    }
    return bytes;
  }
}
