import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/analytics/analytics_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/schema/favorites_record.dart';
import '/backend/schema/places_record.dart';
import '/backend/schema/reviews_record.dart';
import '/features/accessibility/accessibility_score.dart';
import '/l10n/app_strings.dart';
import '/pages/submit_accessibility_report/submit_accessibility_report_widget.dart';

export 'place_categories.dart';
export 'place_explorer_page.dart';

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({super.key, required this.place});
  final PlacesRecord place;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  bool _savingFavorite = false;
  bool _isFavorited = false;
  bool _isReadingAloud = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    final compat = AccessibilityScorer.evaluatePlace(
      widget.place,
      mobilityType:
          currentUserDocument?.snapshotData['mobility_type'] as String?,
    );
    AnalyticsService.instance.logPlaceViewed(
      placeId: widget.place.reference.id,
      category: widget.place.category,
      scorePercent: compat.scorePercent,
      accessibilityLevel: compat.level.name,
      isPersonalized: compat.isPersonalized,
    );
  }

  Future<void> _checkFavorite() async {
    final uid = currentUserUid;
    if (uid.isEmpty) return;
    try {
      final doc = await FavoritesRecord.collection
          .doc('${uid}_${widget.place.reference.id}')
          .get();
      if (mounted) {
        setState(() => _isFavorited = doc.exists);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final uid = currentUserUid;
    if (uid.isEmpty || _savingFavorite) return;
    setState(() => _savingFavorite = true);
    final id = '${uid}_${widget.place.reference.id}';
    final favorite = FavoritesRecord.collection.doc(id);
    try {
      if (_isFavorited) {
        await favorite.delete();
        if (mounted) setState(() => _isFavorited = false);
        AnalyticsService.instance.logFavoriteToggled(
          placeId: widget.place.reference.id,
          added: false,
        );
        _showMessage('تمت الإزالة من المفضلة');
      } else {
        await favorite.set({
          'userId': uid,
          'placeId': widget.place.reference.id,
          'placeName': widget.place.name,
          'placePhoto': widget.place.photoUrl,
          'placeCategory': widget.place.category,
          'created_at': FieldValue.serverTimestamp(),
        });
        if (mounted) setState(() => _isFavorited = true);
        AnalyticsService.instance.logFavoriteToggled(
          placeId: widget.place.reference.id,
          added: true,
        );
        _showMessage('تمت الإضافة إلى المفضلة');
      }
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? 'تعذر تحديث المفضلة.');
    } finally {
      if (mounted) setState(() => _savingFavorite = false);
    }
  }

  @override
  void dispose() {
    try {
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _toggleReadAloud() async {
    if (_isReadingAloud) {
      await _tts.stop();
      if (mounted) setState(() => _isReadingAloud = false);
      return;
    }

    final place = widget.place;
    final f = place.accessibilityFeatures;
    final isEn = S.isEn(context);
    final compat = AccessibilityScorer.evaluatePlace(
      place,
      mobilityType:
          currentUserDocument?.snapshotData['mobility_type'] as String?,
    );

    String statusSpoken(bool known, bool val, String arName) {
      if (!known) return '$arName لسه مش متحدد';
      return val ? '$arName متوفر' : '$arName مش متوفر';
    }

    final text = isEn
        ? '${place.name}, ${place.category} in ${place.city}. Accessibility score ${compat.scorePercent} percent. '
            '${place.isGenuinelyVerified ? "Field verified." : "Awaiting field audit."} '
            '${place.address.isNotEmpty ? "Address: ${place.address}." : ""}'
        : '${place.name}، تصنيفه ${place.category} في ${place.city}. '
            'نسبة ملاءمته ليك ${compat.scorePercent} في المية. '
            '${place.isGenuinelyVerified ? "المكان ده متراجع وموثق ميدانياً." : "المكان ده مضاف ولسه مستني فحص ميداني."} '
            '${statusSpoken(f.hasWheelchairEntrance(), f.wheelchairEntrance, "المدخل للكراسي")}، '
            'و${statusSpoken(f.hasRamp(), f.ramp, "الرامب")}، '
            'و${statusSpoken(f.hasSuitableElevator(), f.suitableElevator, "الأسانسير")}، '
            'و${statusSpoken(f.hasAccessibleRestroom(), f.accessibleRestroom, "الحمام المجهز")}. '
            '${place.openingHours.isNotEmpty ? "مواعيد العمل: ${place.openingHours}." : ""}';

    try {
      if (isEn) {
        await _tts.setLanguage('en-US');
      } else {
        final hasEg = await _tts.isLanguageAvailable('ar-EG');
        await _tts.setLanguage(hasEg == true ? 'ar-EG' : 'ar');
      }
      await _tts.setSpeechRate(0.48);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isReadingAloud = false);
      });
      if (mounted) setState(() => _isReadingAloud = true);
      await _tts.speak(text);
    } catch (_) {
      if (mounted) setState(() => _isReadingAloud = false);
    }
  }

  Future<void> _openNavigation() async {
    if (!widget.place.hasLocation()) {
      _showMessage('إحداثيات هذا المكان غير متوفرة بعد.');
      return;
    }
    final loc = widget.place.location!;
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}&travelmode=walking';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        AnalyticsService.instance.logNavigationStarted(
          placeId: widget.place.reference.id,
          navigationMode: 'maps',
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('تعذر فتح تطبيق الخرائط.');
      }
    } catch (e) {
      _showMessage('تعذر فتح الخرائط: $e');
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    try {
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _openWeb(String url) async {
    final target = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(target);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showAddReviewDialog() {
    double selectedRating = 5.0;
    final commentController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'أضف تقييمك لمستوى الإتاحة',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'إغلاق',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          tooltip: 'تقييم $starIndex من 5 نجوم',
                          icon: Icon(
                            starIndex <= selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFD97706),
                            size: 36,
                          ),
                          onPressed: () => setModalState(
                              () => selectedRating = starIndex.toDouble()),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظاتك عن تجربة المكان',
                      hintText:
                          'مثال: المنحدر ممتاز ومناسب للكراسي، لكن الباب يحتاج مساعدة للفتح.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (currentUserUid.isEmpty ||
                                currentUserIsAnonymous) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'يرجى تسجيل الدخول بحساب لإضافة تقييم.')),
                              );
                              return;
                            }
                            if (commentController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('يرجى كتابة تعليق توضيحي.')),
                              );
                              return;
                            }
                            setModalState(() => submitting = true);
                            try {
                              await ReviewsRecord.collection.add({
                                'place_id': widget.place.reference.id,
                                'createdBy': currentUserUid,
                                'user_name': currentUserDisplayName.isNotEmpty
                                    ? currentUserDisplayName
                                    : 'مستخدم ONEWAY',
                                'rating': selectedRating,
                                'comment': commentController.text.trim(),
                                'status': 'published',
                                'created_at': FieldValue.serverTimestamp(),
                              });
                              AnalyticsService.instance.logReviewSubmitted(
                                placeId: widget.place.reference.id,
                                rating: selectedRating,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _showMessage(
                                  'تم إضافة تقييمك بنجاح. شكراً لمساهمتك!');
                            } catch (e) {
                              setModalState(() => submitting = false);
                              _showMessage('تعذر إضافة التقييم: $e');
                            }
                          },
                    child: Text(submitting ? 'جارٍ الحفظ...' : 'نشر التقييم'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _sharePlace() async {
    final place = widget.place;
    final f = place.accessibilityFeatures;
    final highlights = <String>[
      if (f.wheelchairEntrance) S.t(context, 'مدخل مناسب للكراسي', 'Wheelchair entrance'),
      if (f.ramp) S.t(context, 'منحدر (Ramp)', 'Ramp'),
      if (f.suitableElevator) S.t(context, 'مصعد مجهز', 'Accessible elevator'),
      if (f.accessibleRestroom) S.t(context, 'دورة مياه مهيأة', 'Accessible restroom'),
      if (f.accessibleParking) S.t(context, 'موقف سيارات مخصص', 'Accessible parking'),
    ];
    final locUrl = place.location != null
        ? 'https://maps.google.com/?q=${place.location!.latitude},${place.location!.longitude}'
        : '';
    final lines = <String>[
      '📍 ${place.name}',
      if (place.category.isNotEmpty) '🏷️ ${place.category}',
      if (place.address.isNotEmpty) '📌 ${place.address}',
      if (highlights.isNotEmpty)
        '♿ ${S.t(context, "مميزات الإتاحة", "Accessibility")}: ${highlights.join(" • ")}',
      if (locUrl.isNotEmpty) '🗺️ $locUrl',
      '',
      S.t(context, 'عبر تطبيق ONEWAY — مصر بدون عوائق',
          'Shared via ONEWAY — Barrier-Free Egypt'),
    ];
    final shareText = lines.join('\n');
    final waUri = Uri.parse(
        'https://wa.me/?text=${Uri.encodeComponent(shareText)}');
    try {
      if (await canLaunchUrl(waUri)) {
        AnalyticsService.instance.logSharePlace(
          placeId: place.reference.id,
          method: 'whatsapp',
        );
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: shareText));
    AnalyticsService.instance.logSharePlace(
      placeId: place.reference.id,
      method: 'clipboard',
    );
    if (mounted) {
      _showMessage(S.t(context, 'تم نسخ تفاصيل المكان للمشاركة!',
          'Place details copied for sharing!'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final place = widget.place;
    final features = place.accessibilityFeatures;
    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        actions: [
          IconButton(
            tooltip: _isReadingAloud
                ? S.t(context, 'إيقاف القراءة الصوتية', 'Stop reading aloud')
                : S.t(context, 'استمع لتفاصيل المكان باللهجة المصرية',
                    'Listen to place details'),
            onPressed: _toggleReadAloud,
            icon: Icon(
              _isReadingAloud
                  ? Icons.stop_circle_outlined
                  : Icons.volume_up_rounded,
              color: _isReadingAloud ? theme.error : theme.primary,
            ),
          ),
          IconButton(
            tooltip: S.t(context, 'مشاركة المكان', 'Share Place'),
            onPressed: _sharePlace,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: _isFavorited
                ? S.t(context, 'إزالة من المفضلة', 'Remove from Favorites')
                : S.t(context, 'إضافة إلى المفضلة', 'Add to Favorites'),
            onPressed: _savingFavorite ? null : _toggleFavorite,
            icon: _savingFavorite
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? theme.error : null,
                  ),
          ),
        ],
      ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: place.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: place.photoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: theme.surfaceVariant,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => Image.asset(
                        'assets/images/hero_pyramids.jpg',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/images/hero_pyramids.jpg',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StatusChip(status: place.effectiveVerificationStatus),
                CompatibilityBadge(
                  result: AccessibilityScorer.evaluatePlace(
                    place,
                    mobilityType: currentUserDocument
                        ?.snapshotData['mobility_type'] as String?,
                  ),
                ),
                if (place.category.isNotEmpty)
                  Chip(
                    backgroundColor: theme.primary.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: theme.primary.withValues(alpha: 0.28),
                    ),
                    label: Text(
                      place.category,
                      style: TextStyle(
                        color: theme.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              place.description.isEmpty
                  ? 'لا يوجد وصف متاح بعد.'
                  : place.description,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Navigation & Contact Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.info,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _openNavigation,
                    icon: const Icon(Icons.directions),
                    label: Text(S.t(context, 'الاتجاهات على الخريطة',
                        'Directions')),
                  ),
                ),
                if (place.phoneNumber.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: S.t(context, 'اتصال هاتفياً', 'Call'),
                    onPressed: () => _makeCall(place.phoneNumber),
                    icon: const Icon(Icons.phone),
                  ),
                ],
                if (place.website.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: S.t(context, 'زيارة الموقع', 'Website'),
                    onPressed: () => _openWeb(place.website),
                    icon: const Icon(Icons.language),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: S.t(context, 'مشاركة المكان', 'Share Place'),
                  onPressed: _sharePlace,
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Accessibility Features
            Text(
              S.t(context, 'معلومات الإتاحة الموثقة', 'Accessibility Features'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _FeatureRow(
                label: S.t(context, 'مدخل مناسب للكرسي المتحرك',
                    'Wheelchair-accessible entrance'),
                known: features.hasWheelchairEntrance(),
                value: features.wheelchairEntrance),
            _FeatureRow(
                label: S.t(context, 'منحدر (Ramp)', 'Ramp available'),
                known: features.hasRamp(),
                value: features.ramp),
            _FeatureRow(
                label: S.t(context, 'مصعد مجهز ومناسب', 'Suitable elevator'),
                known: features.hasSuitableElevator(),
                value: features.suitableElevator),
            _FeatureRow(
                label: S.t(context, 'حمام مخصص لذوي الإعاقة',
                    'Accessible restroom'),
                known: features.hasAccessibleRestroom(),
                value: features.accessibleRestroom),
            _FeatureRow(
                label: S.t(context, 'موقف سيارات مخصص ومجهز',
                    'Accessible parking'),
                known: features.hasAccessibleParking(),
                value: features.accessibleParking),
            if (features.corridorWidth.isNotEmpty)
              _InfoRow(
                  label: S.t(context, 'عرض الممرات', 'Corridor width'),
                  value: features.corridorWidth),
            if (features.entranceObstacles.isNotEmpty)
              _InfoRow(
                  label: S.t(context, 'عوائق المدخل إن وجدت',
                      'Entrance obstacles'),
                  value: features.entranceObstacles),
            if (place.amenities.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                S.t(context, 'التجهيزات والخدمات المتوفرة', 'Available Amenities'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: place.amenities
                    .map(
                      (a) => Chip(
                        avatar: Icon(Icons.check_circle_outline_rounded,
                            size: 16, color: theme.primary),
                        label: Text(a),
                        backgroundColor: theme.primary.withValues(alpha: 0.08),
                        side: BorderSide(
                          color: theme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Detailed Accessibility Photos: Entrance, Elevator, Restroom
            Text(
              S.t(context, 'صور تفصيلية للمدخل والمصعد والحمام',
                  'Detailed Accessibility Photos'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _DetailedAccessibilityPhotos(
              entranceUrl: place.entrancePhotoUrl,
              elevatorUrl: place.elevatorPhotoUrl,
              restroomUrl: place.restroomPhotoUrl,
            ),
            const SizedBox(height: 20),

            // Place Address & Verification Info
            Text('تفاصيل العنوان والتحقق',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (place.address.isNotEmpty)
              _InfoRow(label: 'العنوان', value: place.address),
            if (place.city.isNotEmpty)
              _InfoRow(
                  label: 'المدينة / المحافظة',
                  value: '${place.city} - ${place.governorate}'),
            if (place.openingHours.isNotEmpty)
              _InfoRow(label: 'مواعيد العمل', value: place.openingHours),
            _InfoRow(
                label: 'حالة التحقق',
                value: _statusLabel(place.effectiveVerificationStatus)),
            _InfoRow(
                label: 'تاريخ آخر فحص',
                value: place.lastVerifiedAt == null
                    ? 'غير متاح'
                    : '${place.lastVerifiedAt!.day}/${place.lastVerifiedAt!.month}/${place.lastVerifiedAt!.year}'),
            const SizedBox(height: 24),

            // Community Reviews Section
            Row(
              children: [
                Expanded(
                  child: Text(
                    'تقييمات وتجارب المجتمع',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('أضف تقييمك'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: ReviewsRecord.collection
                  .where('place_id', isEqualTo: place.reference.id)
                  .where('status', isEqualTo: 'published')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'تعذر تحميل التقييمات حالياً.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodySmall,
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snapshot.data!.docs
                    .map(ReviewsRecord.fromSnapshot)
                    .toList();

                if (reviews.isEmpty) {
                  return Card(
                    color: theme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.star_outline,
                              size: 36, color: theme.tertiary),
                          const SizedBox(height: 8),
                          const Text(
                            'كن أول من يقيّم مستوى الإتاحة في هذا المكان!',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _showAddReviewDialog,
                            child: const Text('كتابة أول تقييم'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final avgRating =
                    reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                        reviews.length;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.tertiaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFB45309), size: 28),
                          const SizedBox(width: 8),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'من 5 (${reviews.length} تقييم)',
                            style: TextStyle(color: theme.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...reviews.map((r) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.userName.isEmpty
                                            ? 'مستخدم ONEWAY'
                                            : r.userName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < r.rating.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: theme.tertiary,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (r.comment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r.comment),
                                ],
                              ],
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Report problem button (strictly linked to this registered place)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SubmitAccessibilityReportWidget(place: place),
              )),
              icon: Icon(Icons.report_problem_outlined,
                  color: theme.error),
              label: Text(
                  S.t(context, 'الإبلاغ عن معلومة غير دقيقة أو عائق بهذا المكان',
                      'Report an inaccuracy or barrier at this place'),
                  style: TextStyle(color: theme.error)),
            ),
            const SizedBox(height: 8),
            Text(
              S.t(
                context,
                'تُفتح الاتجاهات بوضع المشي (Walking) كإرشاد تقريبي ولا تمثل مساراً معتمداً 100% للكرسي المتحرك.',
                'Directions open in pedestrian walking mode and are not guaranteed wheelchair-accessible paths.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.secondaryText),
            ),
          ],
        ),
      );
  }
}

/// Delegates directly to [SubmitAccessibilityReportWidget] so all barrier
/// reports follow the single registered-places-only workflow.
class SubmitReportPage extends StatelessWidget {
  const SubmitReportPage({super.key, required this.place});
  final PlacesRecord place;

  @override
  Widget build(BuildContext context) =>
      SubmitAccessibilityReportWidget(place: place);
}

class FavoritePlacesPage extends StatelessWidget {
  const FavoritePlacesPage({super.key});

  Future<void> _openFavoritePlace(
    BuildContext context,
    FavoritesRecord favorite,
  ) async {
    if (favorite.placeId.trim().isEmpty) return;
    try {
      final place = await PlacesRecord.getDocumentOnce(
        PlacesRecord.collection.doc(favorite.placeId),
      );
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح تفاصيل هذا المكان حالياً.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('المفضلة')),
          body: StreamBuilder<QuerySnapshot>(
            stream: FavoritesRecord.collection
                .where('userId', isEqualTo: currentUserUid)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _ErrorState(error: snapshot.error);
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final favorites = snapshot.data!.docs
                  .map(FavoritesRecord.fromSnapshot)
                  .toList();
              if (favorites.isEmpty) {
                return const _EmptyState(
                    message: 'لم تضف أي أماكن إلى المفضلة بعد.');
              }
              return ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (ctx, index) {
                  final favorite = favorites[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(favorite.placeName),
                    subtitle: Text(favorite.placeCategory),
                    onTap: () => _openFavoritePlace(ctx, favorite),
                    trailing: IconButton(
                      tooltip: 'إزالة من المفضلة',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => favorite.reference.delete(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(
      {required this.label, required this.known, required this.value});
  final String label;
  final bool known;
  final bool value;
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(
            known
                ? (value ? Icons.check_circle : Icons.cancel)
                : Icons.help_outline,
            color: known ? (value ? Colors.teal : Colors.red) : Colors.orange),
        title: Text(label),
        trailing: Text(known ? (value ? 'متاح' : 'غير متاح') : 'غير معروف'),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      ListTile(title: Text(label), trailing: Text(value));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Chip(label: Text(_statusLabel(status)));
}

String _statusLabel(String status) => switch (status) {
      'verified' => 'تم التحقق ميدانياً ✓',
      'pendingFieldAudit' => 'مضاف - بانتظار فحص ميداني',
      'needsUpdate' => 'يحتاج إلى تحديث',
      'incomplete' => 'معلومات غير مكتملة',
      'reportUnderReview' => 'بلاغ قيد المراجعة',
      _ => 'معلومات غير مكتملة',
    };

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.message =
        'لا توجد أماكن مطابقة. أزل بعض الفلاتر أو أضف مكاناً للمراجعة.',
  });

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});
  final Object? error;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
            child: Text(
                'تعذر تحميل البيانات. تحقق من الاتصال والصلاحيات ثم أعد المحاولة.\n$error',
                textAlign: TextAlign.center)),
      );
}

/// Detailed accessibility photo cards for Entrance/Ramp, Elevator, and Restroom
/// with a full-screen zoomable lightbox viewer.
class _DetailedAccessibilityPhotos extends StatelessWidget {
  const _DetailedAccessibilityPhotos({
    required this.entranceUrl,
    required this.elevatorUrl,
    required this.restroomUrl,
  });

  final String entranceUrl;
  final String elevatorUrl;
  final String restroomUrl;

  void _openPhotoViewer(BuildContext context, String title, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final slots = <({
      String title,
      IconData icon,
      String url,
    })>[
      (
        title: S.t(context, 'المدخل / المنحدر', 'Entrance / Ramp'),
        icon: Icons.accessible_rounded,
        url: entranceUrl.trim(),
      ),
      (
        title: S.t(context, 'المصعد', 'Elevator'),
        icon: Icons.elevator_rounded,
        url: elevatorUrl.trim(),
      ),
      (
        title: S.t(context, 'دورة المياه المهيأة', 'Accessible Restroom'),
        icon: Icons.wc_rounded,
        url: restroomUrl.trim(),
      ),
    ];

    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final slot = slots[index];
          final hasPhoto = slot.url.isNotEmpty;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: hasPhoto
                ? () => _openPhotoViewer(context, slot.title, slot.url)
                : null,
            child: Container(
              width: 156,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasPhoto ? theme.primary : theme.divider,
                  width: hasPhoto ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: hasPhoto
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: slot.url,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: theme.surfaceVariant,
                                  alignment: Alignment.center,
                                  child: const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: theme.surfaceVariant,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: theme.secondaryText,
                                    size: 32,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: theme.surfaceVariant,
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(slot.icon,
                                    color: theme.primary.withValues(alpha: 0.65),
                                    size: 30),
                                const SizedBox(height: 6),
                                Text(
                                  S.t(context, 'لم تُضف صورة بعد',
                                      'No photo yet'),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    color: theme.surface,
                    child: Row(
                      children: [
                        Icon(slot.icon, size: 15, color: theme.primary),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            slot.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.bodySmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
