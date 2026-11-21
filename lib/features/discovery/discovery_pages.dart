import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/schema/accessibility_reports_record.dart';
import '/backend/schema/favorites_record.dart';
import '/backend/schema/places_record.dart';
import '/backend/schema/reviews_record.dart';
import '/backend/seed_data.dart';
import '/features/emergency/emergency_service.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';

String _normalizeArabic(String input) => input
    .trim()
    .toLowerCase()
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');

class PlaceExplorerPage extends StatefulWidget {
  const PlaceExplorerPage({super.key});

  @override
  State<PlaceExplorerPage> createState() => _PlaceExplorerPageState();
}

class _PlaceExplorerPageState extends State<PlaceExplorerPage> {
  final _search = TextEditingController();
  String? _category;
  bool _rampOnly = false;
  bool _restroomOnly = false;
  bool _verifiedOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PlacesRecord> _filter(List<PlacesRecord> places) {
    final query = _normalizeArabic(_search.text);
    return places.where((place) {
      final searchable = _normalizeArabic(
        '${place.name} ${place.category} ${place.address} ${place.city} ${place.governorate}',
      );
      final features = place.accessibilityFeatures;
      return (query.isEmpty || searchable.contains(query)) &&
          (_category == null || place.category == _category) &&
          (!_rampOnly || (features.hasRamp() && features.ramp)) &&
          (!_restroomOnly ||
              (features.hasAccessibleRestroom() &&
                  features.accessibleRestroom)) &&
          (!_verifiedOnly || place.isGenuinelyVerified);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اعرف المكان قبل ما تروح'),
          actions: [
            if (currentUserIsAdmin)
              IconButton(
                tooltip: 'لوحة تحكم الإدارة',
                onPressed: () => context.pushNamed('AdminDashboard'),
                icon:
                    Icon(Icons.admin_panel_settings, color: theme.tertiary),
              ),
            IconButton(
              tooltip: 'الإشعارات',
              onPressed: () => context.pushNamed('NotificationsPage'),
              icon: const Icon(Icons.notifications_outlined),
            ),
            IconButton(
              tooltip: 'بلاغاتي',
              onPressed: () => context.pushNamed('MyReports'),
              icon: const Icon(Icons.assignment_outlined),
            ),
            IconButton(
              tooltip: 'المفضلة',
              onPressed: () => context.pushNamed(FavoritesPageWidget.routeName),
              icon: const Icon(Icons.favorite_outline),
            ),
            IconButton(
              tooltip: 'الإعدادات',
              onPressed: () => context.pushNamed(SettingsPageWidget.routeName),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: PlacesRecord.collection
              .where('verification_status', isEqualTo: 'verified')
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _ErrorState(error: snapshot.error);
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final places = snapshot.data!.docs
                .map(PlacesRecord.fromSnapshot)
                .toList(growable: false);
            final categories = places
                .map((place) => place.category)
                .where((category) => category.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            final filtered = _filter(places);
            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'ابحث عن مكان أو مدينة أو فئة',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('الكل'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                      ...categories.map((category) => ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (selected) => setState(
                              () => _category = selected ? category : null,
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('منحدر متاح'),
                        selected: _rampOnly,
                        onSelected: (value) =>
                            setState(() => _rampOnly = value),
                      ),
                      FilterChip(
                        label: const Text('حمام مجهز'),
                        selected: _restroomOnly,
                        onSelected: (value) =>
                            setState(() => _restroomOnly = value),
                      ),
                      FilterChip(
                        label: const Text('تم التحقق فقط'),
                        selected: _verifiedOnly,
                        onSelected: (value) =>
                            setState(() => _verifiedOnly = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('النتائج (${filtered.length})',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    _EmptyState(isDatabaseEmpty: places.isEmpty)
                  else
                    ...filtered.map((place) => _PlaceTile(place: place)),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (index) {
            switch (index) {
              case 1:
                context.pushNamed(ExploreMapWidget.routeName);
              case 2:
                context.pushNamed(VoiceAssistantInterfaceWidget.routeName);
              case 3:
                context.pushNamed(EmergencySOSWidget.routeName);
            }
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'الرئيسية'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'الخريطة'),
            NavigationDestination(
                icon: Icon(Icons.record_voice_over_outlined),
                selectedIcon: Icon(Icons.record_voice_over),
                label: 'المساعد'),
            NavigationDestination(
                icon: Icon(Icons.emergency_outlined),
                selectedIcon: Icon(Icons.emergency),
                label: 'طوارئ'),
          ],
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place});
  final PlacesRecord place;

  @override
  Widget build(BuildContext context) {
    final features = place.accessibilityFeatures;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(place.name.isEmpty ? 'مكان بدون اسم' : place.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.category.isNotEmpty) Text(place.category),
            if (place.address.isNotEmpty) Text(place.address),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              _StatusChip(status: place.effectiveVerificationStatus),
              if (features.hasRamp() && features.ramp)
                const Chip(label: Text('منحدر')),
              if (features.hasAccessibleRestroom() &&
                  features.accessibleRestroom)
                const Chip(label: Text('حمام مجهز')),
            ]),
          ],
        ),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place)),
        ),
      ),
    );
  }
}

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({super.key, required this.place});
  final PlacesRecord place;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  bool _savingFavorite = false;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
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
        _showMessage('تمت الإضافة إلى المفضلة');
      }
    } on FirebaseException catch (error) {
      if (mounted) _showMessage(error.message ?? 'تعذر تحديث المفضلة.');
    } finally {
      if (mounted) setState(() => _savingFavorite = false);
    }
  }

  Future<void> _openNavigation() async {
    if (!widget.place.hasLocation()) {
      _showMessage('إحداثيات هذا المكان غير متوفرة بعد.');
      return;
    }
    final loc = widget.place.location!;
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'أضف تقييمك لمستوى الإتاحة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
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
                        icon: Icon(
                          starIndex <= selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
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
    );
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final place = widget.place;
    final features = place.accessibilityFeatures;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(place.name),
          actions: [
            IconButton(
              tooltip: _isFavorited ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
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
                  ? Image.network(
                      place.photoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusChip(status: place.effectiveVerificationStatus),
                if (place.category.isNotEmpty)
                  Chip(
                    backgroundColor: theme.primaryLight,
                    label: Text(
                      place.category,
                      style: TextStyle(
                          color: theme.primary, fontWeight: FontWeight.bold),
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
                    label: const Text('الاتجاهات على الخريطة'),
                  ),
                ),
                if (place.phoneNumber.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'اتصال هاتفياً',
                    onPressed: () => _makeCall(place.phoneNumber),
                    icon: const Icon(Icons.phone),
                  ),
                ],
                if (place.website.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'زيارة الموقع',
                    onPressed: () => _openWeb(place.website),
                    icon: const Icon(Icons.language),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Accessibility Features
            Text('معلومات الإتاحة الموثقة',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _FeatureRow(
                label: 'مدخل مناسب للكرسي المتحرك',
                known: features.hasWheelchairEntrance(),
                value: features.wheelchairEntrance),
            _FeatureRow(
                label: 'منحدر (Ramp)',
                known: features.hasRamp(),
                value: features.ramp),
            _FeatureRow(
                label: 'مصعد مجهز ومناسب',
                known: features.hasSuitableElevator(),
                value: features.suitableElevator),
            _FeatureRow(
                label: 'حمام مخصص لذوي الإعاقة',
                known: features.hasAccessibleRestroom(),
                value: features.accessibleRestroom),
            _FeatureRow(
                label: 'موقف سيارات مخصص ومجهز',
                known: features.hasAccessibleParking(),
                value: features.accessibleParking),
            if (features.corridorWidth.isNotEmpty)
              _InfoRow(label: 'عرض الممرات', value: features.corridorWidth),
            if (features.entranceObstacles.isNotEmpty)
              _InfoRow(
                  label: 'عوائق المدخل إن وجدت',
                  value: features.entranceObstacles),
            const SizedBox(height: 16),

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('تقييمات وتجارب المجتمع',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: _showAddReviewDialog,
                  icon: const Icon(Icons.rate_review_outlined),
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
                          Icon(Icons.star, color: theme.tertiary, size: 28),
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
                                    Text(
                                      r.userName.isEmpty
                                          ? 'مستخدم ONEWAY'
                                          : r.userName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Row(
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

            // Report problem button
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SubmitReportPage(place: place),
              )),
              icon: Icon(Icons.report_problem_outlined,
                  color: theme.error),
              label: Text('الإبلاغ عن معلومة غير دقيقة أو عائق جديد',
                  style: TextStyle(color: theme.error)),
            ),
            const SizedBox(height: 8),
            Text(
              'الاتجاهات في هذه المرحلة هي تنقّل عادي ولا تمثل مساراً مؤكداً للكرسي المتحرك.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({super.key, required this.place});
  final PlacesRecord place;

  @override
  State<SubmitReportPage> createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  final _description = TextEditingController();
  String _category = 'مدخل غير مناسب';
  bool _submitting = false;
  XFile? _imageFile;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _imageFile = picked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التقاط أو اختيار الصورة: $e')),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('اختيار صورة من المعرض'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_description.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب وصفاً واضحاً للعائق قبل الإرسال.')),
      );
      return;
    }
    setState(() => _submitting = true);

    try {
      final List<String> photoUrls = [];

      // Upload image to Firebase Storage if selected
      if (_imageFile != null) {
        try {
          final bytes = await _imageFile!.readAsBytes();
          final fileName =
              'reports/${DateTime.now().millisecondsSinceEpoch}_${currentUserUid}.jpg';
          final storageRef = FirebaseStorage.instance.ref().child(fileName);
          final uploadTask = await storageRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          photoUrls.add(downloadUrl);
        } catch (storageError) {
          debugPrint('Storage upload error: $storageError');
        }
      }

      // Determine GPS location coordinates
      GeoPoint reportLocation = widget.place.hasLocation()
          ? GeoPoint(
              widget.place.location!.latitude, widget.place.location!.longitude)
          : const GeoPoint(30.0444, 31.2357);

      try {
        final pos = await EmergencyService.determineCurrentPosition();
        if (pos != null) {
          reportLocation = GeoPoint(pos.latitude, pos.longitude);
        }
      } catch (_) {}

      final placeName =
          widget.place.name.isNotEmpty ? widget.place.name : 'عائق في الطريق';

      await AccessibilityReportsRecord.collection.add({
        'place_id': widget.place.reference.id,
        'place_name': placeName,
        'createdBy': currentUserUid,
        'user_name': currentUserDisplayName.isNotEmpty
            ? currentUserDisplayName
            : 'مستخدم ONEWAY',
        'problemCategory': _category,
        'description': _description.text.trim(),
        'photo_urls': photoUrls,
        'location': reportLocation,
        'status': 'new',
        'created_at': FieldValue.serverTimestamp(),
      });

      // Send confirmation in-app notification
      if (currentUserUid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': currentUserUid,
          'title': 'تم استلام بلاغك بنجاح',
          'body': 'بلاغك عن ($placeName) قيد المراجعة لدى فريق التحقق.',
          'type': 'report_status',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال البلاغ بنجاح وهو قيد المراجعة من الإدارة.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'تعذر إرسال البلاغ.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('إبلاغ عن عائق')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                widget.place.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'نوع العائق أو المشكلة',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  'منحدر مفقود',
                  'مدخل غير مناسب',
                  'مصعد غير مناسب',
                  'حمام غير مجهز',
                  'ممر ضيق',
                  'رصيف مسدود',
                  'موقف مخصص مفقود',
                  'معلومة غير دقيقة',
                  'أخرى'
                ]
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'وصف المشكلة بالتفصيل',
                  hintText: 'اشرح ما واجهته بدقة للمساعدة في التحقق...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Photo attachment section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صورة العائق (اختياري)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _showImageSourcePicker,
                            icon: const Icon(Icons.add_a_photo),
                            label: Text(_imageFile == null
                                ? 'إضافة صورة'
                                : 'تغيير الصورة'),
                          ),
                        ],
                      ),
                      if (_imageFile != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _imageFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _imageFile = null),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'جارٍ رفع البلاغ…' : 'إرسال البلاغ'),
              ),
              const SizedBox(height: 12),
              const Text(
                'لن يُعامل البلاغ كمعلومة مؤكدة في التطبيق قبل مراجعته من الإدارة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
}

class FavoritePlacesPage extends StatelessWidget {
  const FavoritePlacesPage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('المفضلة')),
          body: StreamBuilder<QuerySnapshot>(
            stream: FavoritesRecord.collection
                .where('userId', isEqualTo: currentUserUid)
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
                itemBuilder: (_, index) {
                  final favorite = favorites[index];
                  return ListTile(
                    title: Text(favorite.placeName),
                    subtitle: Text(favorite.placeCategory),
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
      'verified' => 'تم التحقق',
      'demoUnverified' => 'بيانات تجريبية - غير موثقة',
      'needsUpdate' => 'يحتاج إلى تحديث',
      'incomplete' => 'معلومات غير مكتملة',
      'reportUnderReview' => 'بلاغ قيد المراجعة',
      _ => 'معلومات غير مكتملة',
    };

class _EmptyState extends StatefulWidget {
  const _EmptyState({
    this.message =
        'لا توجد أماكن مطابقة. أزل بعض الفلاتر أو أضف مكاناً للمراجعة.',
    this.isDatabaseEmpty = false,
  });

  final String message;
  final bool isDatabaseEmpty;

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  bool _loading = false;
  String? _status;

  Future<void> _seed() async {
    setState(() {
      _loading = true;
      _status = null;
    });
    try {
      final count = await OnewayDataSeeder.seedPlaces();
      if (mounted) {
        setState(() => _status = 'تم استيراد $count أماكن بنجاح!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'تعذر الاستيراد: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isDatabaseEmpty
                    ? (currentUserIsModerator
                        ? 'قاعدة بيانات الأماكن فارغة حالياً.\nيمكنك استيراد مجموعة الأماكن الأولية المعتمدة في القاهرة والجيزة للبدء فوراً.'
                        : 'الأماكن المجهزة هتظهر هنا أول ما تتضاف.\nجرب تاني بعد شوية.')
                    : widget.message,
                textAlign: TextAlign.center,
              ),
              // Only admins/moderators can seed: Firestore rules deny the
              // write for regular users, so we never show them the button.
              if (widget.isDatabaseEmpty && currentUserIsModerator) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _seed,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(_loading
                      ? 'جارٍ استيراد الأماكن…'
                      : 'استيراد الأماكن المصرية المعتمدة (8 أماكن)'),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 10),
                  Text(_status!,
                      style: TextStyle(
                          color: _status!.contains('نجاح')
                              ? FlutterFlowTheme.of(context).success
                              : FlutterFlowTheme.of(context).error),
                      textAlign: TextAlign.center),
                ],
              ],
            ],
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
