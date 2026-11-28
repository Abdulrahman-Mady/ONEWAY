import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/core/utils/image_compression_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/app_strings.dart';

/// Shared helper for picking, compressing on-device, and uploading
/// place/business images safely across Android, iOS, and Web.
class PlacePhotoUploadHelper {
  PlacePhotoUploadHelper._();

  static final ImagePicker _picker = ImagePicker();

  static Future<Uint8List?> pickImageBytes({
    ImageSource source = ImageSource.gallery,
    double maxWidth = 1280,
    int imageQuality = 78,
  }) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
    if (file == null) return null;
    final raw = await file.readAsBytes();
    return ImageCompressionService.compressForUpload(raw);
  }

  /// Compresses [bytes] on-device and uploads under
  /// `users/{uid}/{folder}/{prefix}_{ts}.jpg` to minimize Storage & Bandwidth.
  static Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String uid,
    required String folder,
    required String prefix,
  }) async {
    final optimized = await ImageCompressionService.compressForUpload(bytes);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref('users/$uid/$folder/${prefix}_$ts.jpg');
    await ref.putData(
      optimized,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}

/// Visual main-photo picker card (Gallery / Camera + instant preview + remove)
/// replacing raw URL inputs across Admin Place Editor and Business Registration.
class MainPhotoPickerCard extends StatelessWidget {
  const MainPhotoPickerCard({
    super.key,
    required this.onPickGallery,
    this.onPickCamera,
    this.onRemove,
    this.imageBytes,
    this.imageUrl,
    this.isUploading = false,
    this.title,
    this.subtitle,
    this.compact = false,
  });

  final VoidCallback onPickGallery;
  final VoidCallback? onPickCamera;
  final VoidCallback? onRemove;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool isUploading;
  final String? title;
  final String? subtitle;
  final bool compact;

  bool get _hasPhoto =>
      imageBytes != null || (imageUrl != null && imageUrl!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final effectiveTitle =
        title ?? S.t(context, 'الصورة الرئيسية للمكان', 'Main Place Photo');
    final effectiveSubtitle = subtitle ??
        S.t(
          context,
          'اختر صورة واضحة لواجهة أو مدخل المكان من جهازك',
          'Pick a clear photo of the entrance or venue from your device',
        );
    final previewHeight = compact ? 124.0 : 164.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _hasPhoto ? theme.primary.withValues(alpha: 0.45) : theme.divider,
          width: _hasPhoto ? 1.5 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header strip
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_back_rounded,
                  size: 20,
                  color: theme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    effectiveTitle,
                    style: theme.titleSmall.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ),
                if (_hasPhoto && onRemove != null && !isUploading)
                  TextButton.icon(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.error,
                      minimumSize: const Size(44, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 17),
                    label: Text(
                      S.t(context, 'حذف', 'Remove'),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),

          // Preview or empty dropzone
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: isUploading ? null : onPickGallery,
                child: SizedBox(
                  height: previewHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageBytes != null)
                        Image.memory(imageBytes!, fit: BoxFit.cover)
                      else if (imageUrl != null && imageUrl!.trim().isNotEmpty)
                        Image.network(
                          imageUrl!.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _EmptyPhotoPlaceholder(
                            theme: theme,
                            subtitle: effectiveSubtitle,
                          ),
                        )
                      else
                        _EmptyPhotoPlaceholder(
                          theme: theme,
                          subtitle: effectiveSubtitle,
                        ),
                      if (isUploading)
                        Container(
                          color: Colors.black.withValues(alpha: 0.48),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  S.t(context, 'جارٍ رفع الصورة...',
                                      'Uploading photo...'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    key: const Key('pick_main_photo_gallery_btn'),
                    onPressed: isUploading ? null : onPickGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(
                      _hasPhoto
                          ? S.t(context, 'تغيير الصورة', 'Change Photo')
                          : S.t(context, 'اختيار من المعرض', 'From Gallery'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (onPickCamera != null && !kIsWeb) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    key: const Key('pick_main_photo_camera_btn'),
                    onPressed: isUploading ? null : onPickCamera,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(S.t(context, 'كاميرا', 'Camera')),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotoPlaceholder extends StatelessWidget {
  const _EmptyPhotoPlaceholder({
    required this.theme,
    required this.subtitle,
  });

  final FlutterFlowTheme theme;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.surfaceVariant,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              color: theme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.bodySmall.copyWith(
              fontSize: 12.5,
              color: theme.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
